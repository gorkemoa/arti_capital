package com.office701.articapital

import android.app.Activity
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import com.google.android.material.textfield.MaterialAutoCompleteTextView
import com.google.android.material.textfield.TextInputEditText
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.bottomsheet.BottomSheetDialog
import org.json.JSONArray
import org.json.JSONObject
import kotlinx.coroutines.*
import okhttp3.Credentials
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

data class ServiceItem(
    val serviceID: Int,
    val serviceName: String,
    val documents: List<ServiceDocument>
)

data class ServiceDocument(
    val documentID: Int,
    val documentName: String
)

class ShareActivity : AppCompatActivity() {

    private val prefsName = "group.com.office701.articapital"
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    private var allServices: List<ServiceItem> = emptyList()
    private lateinit var ddDocType: MaterialAutoCompleteTextView
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)

        val companies = (prefs.getString("Companies", "") ?: "")
            .split("|")
            .filter { it.isNotBlank() }
        val userRank = prefs.getString("UserRank", "") ?: ""
        val isAdmin = userRank == "50"
        val accountNameDefault = if (isAdmin) {
            prefs.getString("LoggedInUserName", companies.firstOrNull() ?: "") ?: ""
        } else {
            companies.firstOrNull() ?: (prefs.getString("LoggedInUserName", "") ?: "")
        }

        // BottomSheetDialog ile ayrıntılı seçim
        val sheet = BottomSheetDialog(this)
        val view = LayoutInflater.from(this).inflate(R.layout.dialog_share_bottom_sheet, null)
        sheet.setContentView(view)

        val ddCompany = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddCompany)
        val ddProject = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddProject)
        ddDocType = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddDocType)
        val etNote = view.findViewById<TextInputEditText>(R.id.etNote)
        val btnProject = view.findViewById<Button>(R.id.btnProject)
        val btnMessage = view.findViewById<Button>(R.id.btnMessage)
        val loadingView = view.findViewById<View>(R.id.loadingView)

        // Admin ise tek seçenek: Mesaj
        if (isAdmin) {
            btnProject.visibility = View.GONE
        }

        // Company adapter
        val companyList = if (companies.isEmpty()) listOf(accountNameDefault) else companies
        ddCompany.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, companyList))
        ddCompany.setText(accountNameDefault, false)

        // Loading göster, servisleri yükle
        loadingView?.visibility = View.VISIBLE
        ddProject.isEnabled = false
        ddDocType.isEnabled = false
        
        scope.launch {
            try {
                allServices = fetchAllServices()
                val projectNames = allServices.map { it.serviceName }
                
                withContext(Dispatchers.Main) {
                    ddProject.setAdapter(ArrayAdapter(this@ShareActivity, android.R.layout.simple_list_item_1, projectNames))
                    if (projectNames.isNotEmpty()) {
                        ddProject.setText(projectNames.first(), false)
                        // İlk servisin belgelerini yükle
                        updateDocumentTypes(allServices.first())
                    }
                    ddProject.isEnabled = true
                    loadingView?.visibility = View.GONE
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    loadingView?.visibility = View.GONE
                    ddProject.isEnabled = true
                    // Fallback: boş liste
                    ddProject.setAdapter(ArrayAdapter(this@ShareActivity, android.R.layout.simple_list_item_1, emptyList<String>()))
                }
            }
        }

        // Proje seçilince belge türlerini güncelle
        ddProject.setOnItemClickListener { _, _, position, _ ->
            if (position < allServices.size) {
                updateDocumentTypes(allServices[position])
            }
        }

        btnProject.setOnClickListener {
            val account = (ddCompany.text?.toString()?.takeIf { it.isNotBlank() } ?: accountNameDefault)
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "project", account = account, folder = folder, docType = docType, note = note)
            sheet.dismiss()
        }
        btnMessage.setOnClickListener {
            val account = (ddCompany.text?.toString()?.takeIf { it.isNotBlank() } ?: accountNameDefault)
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "message", account = account, folder = folder, docType = docType, note = note)
            sheet.dismiss()
        }

        sheet.setOnCancelListener {
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
        sheet.show()
    }

    private fun updateDocumentTypes(service: ServiceItem) {
        currentDocuments = service.documents.map { it.documentName }
        
        ddDocType.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, currentDocuments))
        if (currentDocuments.isNotEmpty()) {
            ddDocType.setText(currentDocuments.first(), false)
        } else {
            ddDocType.setText("", false)
        }
        ddDocType.isEnabled = currentDocuments.isNotEmpty()
    }

    private suspend fun fetchAllServices(): List<ServiceItem> = withContext(Dispatchers.IO) {
        val url = "https://api.office701.com/arti-capital/service/general/general/services/all"
        val credentials = Credentials.basic("Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM", "vRParTCAqTjtmkI17I1EVpPH57Edl0")
        
        val request = Request.Builder()
            .url(url)
            .header("Authorization", credentials)
            .header("Accept", "application/json")
            .get()
            .build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) {
            throw Exception("API Error: ${response.code}")
        }

        val body = response.body?.string() ?: throw Exception("Empty response")
        val json = JSONObject(body)
        val dataObj = json.optJSONObject("data") ?: throw Exception("No data object")
        val servicesArray = dataObj.optJSONArray("services") ?: JSONArray()

        val services = mutableListOf<ServiceItem>()
        for (i in 0 until servicesArray.length()) {
            val serviceObj = servicesArray.getJSONObject(i)
            val serviceID = serviceObj.optInt("serviceID", 0)
            val serviceName = serviceObj.optString("serviceName", "")
            val documentsArray = serviceObj.optJSONArray("documents") ?: JSONArray()
            
            val documents = mutableListOf<ServiceDocument>()
            for (j in 0 until documentsArray.length()) {
                val docObj = documentsArray.getJSONObject(j)
                val documentID = docObj.optInt("documentID", 0)
                val documentName = docObj.optString("documentName", "")
                if (documentName.isNotBlank()) {
                    documents.add(ServiceDocument(documentID, documentName))
                }
            }
            
            if (serviceName.isNotBlank()) {
                services.add(ServiceItem(serviceID, serviceName, documents))
            }
        }
        
        services
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    private fun handleShare(mode: String, account: String, folder: String, docType: String, note: String = "") {
        val payload = JSONObject()
        payload.put("type", "share")
        payload.put("mode", mode)
        payload.put("account", account)
        payload.put("folder", folder)
        payload.put("shareWith", docType)
        if (note.isNotBlank()) payload.put("text", note)

        val itemsArray = JSONArray()
        val intent = intent
        when (intent?.action) {
            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                when {
                    uri != null -> {
                        itemsArray.put(JSONObject().apply {
                            put("path", uri.toString())
                            put("type", guessType(uri))
                        })
                    }
                    !text.isNullOrBlank() -> {
                        itemsArray.put(JSONObject().apply {
                            put("text", text)
                            put("type", "text")
                        })
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val clipData: ClipData? = intent.clipData
                val uris: ArrayList<Uri> = arrayListOf()
                if (clipData != null) {
                    for (i in 0 until clipData.itemCount) {
                        clipData.getItemAt(i).uri?.let { uris.add(it) }
                    }
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris.addAll(it) }
                }
                uris.forEach { u ->
                    itemsArray.put(JSONObject().apply {
                        put("path", u.toString())
                        put("type", guessType(u))
                    })
                }
            }
        }
        payload.put("items", itemsArray)

        // JSON string olarak SharedPreferences'e yaz
        val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        prefs.edit().putString("ShareMediaJSON", payload.toString()).apply()

        // Ana uygulamayı aç
        val mainIntent = Intent(this, MainActivity::class.java)
        mainIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(mainIntent)

        setResult(Activity.RESULT_OK)
        finish()
    }

    private fun guessType(uri: Uri): String {
        val type = contentResolver.getType(uri) ?: return "file"
        return when {
            type.startsWith("image/") -> "image"
            type.startsWith("video/") -> "video"
            else -> "file"
        }
    }
}


