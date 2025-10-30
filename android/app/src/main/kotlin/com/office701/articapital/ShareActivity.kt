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
    val documents: List<ServiceDocument>,
    val appID: Int = 0,
    val compID: Int = 0
)

data class ServiceDocument(
    val documentID: Int,
    val documentName: String,
    val isAdded: Boolean = false
)

data class ExistingDocument(
    val documentID: Int,
    val documentTypeID: Int,
    val documentType: String
)

class ShareActivity : AppCompatActivity() {

    private val prefsName = "group.com.office701.articapital"
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    private var allServices: List<ServiceItem> = emptyList()
    private var filteredServices: List<ServiceItem> = emptyList()
    private var companyToCompIDMap: Map<String, Int> = emptyMap()
    private var currentDocuments: List<String> = emptyList()
    private lateinit var ddDocType: MaterialAutoCompleteTextView
    private lateinit var ddProject: MaterialAutoCompleteTextView
    private var existingDocumentID: Int? = null
    private var existingDocumentTypeID: Int? = null
    private var selectedServiceID: Int? = null
    private var selectedAppID: Int = 0
    private var selectedCompID: Int = 0
    
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
        ddProject = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddProject)
        ddDocType = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddDocType)
        val etNote = view.findViewById<TextInputEditText>(R.id.etNote)
        val btnProject = view.findViewById<Button>(R.id.btnProject)
        val btnUpdate = view.findViewById<Button>(R.id.btnUpdate)
        val btnMessage = view.findViewById<Button>(R.id.btnMessage)
        val loadingView = view.findViewById<View>(R.id.loadingView)

        // Başlangıçta güncelleme butonunu gizle
        btnUpdate.visibility = View.GONE

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
                val servicesData = fetchAllServices()
                allServices = servicesData.first
                companyToCompIDMap = servicesData.second
                
                withContext(Dispatchers.Main) {
                    // İlk olarak seçili firmaya göre projeleri filtrele
                    val selectedCompany = ddCompany.text.toString()
                    filterProjectsByCompany(selectedCompany, btnProject, btnUpdate)
                    
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

        // Firma seçimi değiştiğinde projeleri filtrele
        ddCompany.setOnItemClickListener { _, _, _, _ ->
            val selectedCompany = ddCompany.text.toString()
            filterProjectsByCompany(selectedCompany, btnProject, btnUpdate)
        }

        // Proje seçilince belge türlerini güncelle
        ddProject.setOnItemClickListener { _, _, position, _ ->
            if (position < filteredServices.size) {
                val selectedService = filteredServices[position]
                selectedServiceID = selectedService.serviceID
                selectedAppID = selectedService.appID
                selectedCompID = selectedService.compID
                updateDocumentTypes(selectedService)
            }
        }

        // Belge türü seçilince mevcut belgeyi kontrol et
        ddDocType.setOnItemClickListener { _, _, position, _ ->
            if (selectedAppID > 0 && position < currentDocuments.size) {
                checkExistingDocument(selectedAppID, selectedCompID, position, btnProject, btnUpdate)
            }
        }

        btnProject.setOnClickListener {
            val account = (ddCompany.text?.toString()?.takeIf { it.isNotBlank() } ?: accountNameDefault)
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "project", account = account, folder = folder, docType = docType, note = note, isUpdate = false)
            sheet.dismiss()
        }
        btnUpdate.setOnClickListener {
            val account = (ddCompany.text?.toString()?.takeIf { it.isNotBlank() } ?: accountNameDefault)
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "project", account = account, folder = folder, docType = docType, note = note, isUpdate = true)
            sheet.dismiss()
        }
        btnMessage.setOnClickListener {
            val account = (ddCompany.text?.toString()?.takeIf { it.isNotBlank() } ?: accountNameDefault)
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "message", account = account, folder = folder, docType = docType, note = note, isUpdate = false)
            sheet.dismiss()
        }

        sheet.setOnCancelListener {
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
        sheet.show()
    }

    private fun filterProjectsByCompany(companyName: String, btnProject: Button, btnUpdate: Button) {
        // Firma adından compID bul
        val compID = companyToCompIDMap[companyName] ?: 0
        
        // CompID'ye göre projeleri filtrele
        filteredServices = if (compID > 0) {
            allServices.filter { it.compID == compID }
        } else {
            allServices
        }
        
        val projectNames = filteredServices.map { it.serviceName }
        ddProject.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, projectNames))
        
        if (projectNames.isNotEmpty()) {
            val firstService = filteredServices.first()
            ddProject.setText(projectNames.first(), false)
            // İlk servisin belgelerini yükle
            selectedServiceID = firstService.serviceID
            selectedAppID = firstService.appID
            selectedCompID = firstService.compID
            updateDocumentTypes(firstService)
            
            // İlk belge türü için mevcut belgeyi kontrol et
            if (firstService.documents.isNotEmpty() && selectedAppID > 0) {
                checkExistingDocument(selectedAppID, selectedCompID, 0, btnProject, btnUpdate)
            }
        } else {
            ddProject.setText("", false)
            ddDocType.setText("", false)
            ddDocType.isEnabled = false
        }
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
        
        // Belge türü değişince mevcut belgeyi kontrol et
        existingDocumentID = null
        existingDocumentTypeID = null
    }

    private fun checkExistingDocument(appID: Int, compID: Int, documentPosition: Int, btnProject: Button, btnUpdate: Button) {
        val service = filteredServices.find { it.appID == appID } ?: return
        if (documentPosition >= service.documents.size) return
        
        val document = service.documents[documentPosition]
        val documentTypeID = document.documentID
        
        // isAdded flag'ine göre direkt karar ver
        if (document.isAdded) {
            // Belge zaten eklendi, documentID'yi bul
            scope.launch {
                try {
                    val existingDoc = fetchProjectDocuments(appID, compID, documentTypeID)
                    
                    withContext(Dispatchers.Main) {
                        if (existingDoc != null) {
                            existingDocumentID = existingDoc.documentID
                            existingDocumentTypeID = existingDoc.documentTypeID
                            btnProject.visibility = View.GONE
                            btnUpdate.visibility = View.VISIBLE
                            btnUpdate.text = "Belgeyi Güncelle"
                        } else {
                            // isAdded true ama belge bulunamadı, yeni kayıt yap
                            existingDocumentID = null
                            existingDocumentTypeID = null
                            btnProject.visibility = View.VISIBLE
                            btnUpdate.visibility = View.GONE
                        }
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        existingDocumentID = null
                        existingDocumentTypeID = null
                        btnProject.visibility = View.VISIBLE
                        btnUpdate.visibility = View.GONE
                    }
                }
            }
        } else {
            // Belge eklenmemiş, yeni kayıt
            existingDocumentID = null
            existingDocumentTypeID = null
            btnProject.visibility = View.VISIBLE
            btnUpdate.visibility = View.GONE
        }
    }

    private suspend fun fetchProjectDocuments(appID: Int, compID: Int, documentTypeID: Int): ExistingDocument? = withContext(Dispatchers.IO) {
        try {
            val url = "https://api.office701.com/arti-capital/service/application/project/app/$appID"
            val credentials = Credentials.basic("Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM", "vRParTCAqTjtmkI17I1EVpPH57Edl0")
            
            val request = Request.Builder()
                .url(url)
                .header("Authorization", credentials)
                .header("Accept", "application/json")
                .get()
                .build()

            val response = client.newCall(request).execute()
            if (!response.isSuccessful) {
                return@withContext null
            }

            val body = response.body?.string() ?: return@withContext null
            val json = JSONObject(body)
            val dataObj = json.optJSONObject("data") ?: return@withContext null
            val projectObj = dataObj.optJSONObject("project") ?: return@withContext null
            val documentsArray = projectObj.optJSONArray("documents") ?: return@withContext null
            
            // documentTypeID ile eşleşen belgeyi bul
            for (i in 0 until documentsArray.length()) {
                val docObj = documentsArray.getJSONObject(i)
                val docTypeID = docObj.optInt("documentTypeID", 0)
                
                if (docTypeID == documentTypeID) {
                    val documentID = docObj.optInt("documentID", 0)
                    val documentType = docObj.optString("documentType", "")
                    
                    return@withContext ExistingDocument(
                        documentID = documentID,
                        documentTypeID = docTypeID,
                        documentType = documentType
                    )
                }
            }
            
            null
        } catch (e: Exception) {
            null
        }
    }

    @Deprecated("No longer needed - use fetchProjectDocuments")
    private suspend fun checkDocumentExists(serviceID: Int, documentID: Int): Boolean = withContext(Dispatchers.IO) {
        false
    }

    private suspend fun fetchAllServices(): Pair<List<ServiceItem>, Map<String, Int>> = withContext(Dispatchers.IO) {
        // Önce projeleri getir
        val projectsUrl = "https://api.office701.com/arti-capital/service/application/project/apps"
        val credentials = Credentials.basic("Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM", "vRParTCAqTjtmkI17I1EVpPH57Edl0")
        
        val projectsRequest = Request.Builder()
            .url(projectsUrl)
            .header("Authorization", credentials)
            .header("Accept", "application/json")
            .get()
            .build()

        val projectsResponse = client.newCall(projectsRequest).execute()
        if (!projectsResponse.isSuccessful) {
            throw Exception("Projects API Error: ${projectsResponse.code}")
        }

        val projectsBody = projectsResponse.body?.string() ?: throw Exception("Empty projects response")
        val projectsJson = JSONObject(projectsBody)
        val projectsDataObj = projectsJson.optJSONObject("data") ?: throw Exception("No projects data object")
        val projectsArray = projectsDataObj.optJSONArray("applications") ?: JSONArray()

        // Projeleri ve required documents bilgilerini al
        val services = mutableListOf<ServiceItem>()
        val companyMap = mutableMapOf<String, Int>()
        
        for (i in 0 until projectsArray.length()) {
            val projectObj = projectsArray.getJSONObject(i)
            val appID = projectObj.optInt("appID", 0)
            val compID = projectObj.optInt("compID", 0)
            val appTitle = projectObj.optString("appTitle", "")
            val serviceID = projectObj.optInt("serviceID", 0)
            val compName = projectObj.optString("compName", "")
            
            // Firma-CompID eşleştirmesini kaydet
            if (compName.isNotBlank() && compID > 0) {
                companyMap[compName] = compID
            }
            
            if (appTitle.isBlank() || appID == 0) continue
            
            // Her proje için detayını çek ve requiredDocuments'ı al
            try {
                val detailUrl = "https://api.office701.com/arti-capital/service/application/project/app/$appID"
                val detailRequest = Request.Builder()
                    .url(detailUrl)
                    .header("Authorization", credentials)
                    .header("Accept", "application/json")
                    .get()
                    .build()

                val detailResponse = client.newCall(detailRequest).execute()
                if (detailResponse.isSuccessful) {
                    val detailBody = detailResponse.body?.string()
                    val detailJson = JSONObject(detailBody ?: "")
                    val detailDataObj = detailJson.optJSONObject("data")
                    val projectDetailObj = detailDataObj?.optJSONObject("project")
                    val requiredDocsArray = projectDetailObj?.optJSONArray("requiredDocuments") ?: JSONArray()
                    
                    // RequiredDocuments'tan TÜM belge türlerini al (isAdded true/false fark etmez)
                    val documents = mutableListOf<ServiceDocument>()
                    for (j in 0 until requiredDocsArray.length()) {
                        val docObj = requiredDocsArray.getJSONObject(j)
                        val documentID = docObj.optInt("documentID", 0)
                        val documentName = docObj.optString("documentName", "")
                        val isAdded = docObj.optBoolean("isAdded", false)
                        
                        if (documentName.isNotBlank()) {
                            documents.add(ServiceDocument(documentID, documentName, isAdded))
                        }
                    }
                    
                    // Belge varsa servise ekle (boş olsa bile ekle - belki sonradan belge eklenebilir)
                    services.add(ServiceItem(
                        serviceID = serviceID,
                        serviceName = appTitle,
                        documents = documents,
                        appID = appID,
                        compID = compID
                    ))
                }
            } catch (e: Exception) {
                // Bu proje için hata varsa atla
                continue
            }
        }
        
        Pair(services, companyMap)
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    private fun handleShare(mode: String, account: String, folder: String, docType: String, note: String = "", isUpdate: Boolean = false) {
        val payload = JSONObject()
        payload.put("type", "share")
        payload.put("mode", mode)
        payload.put("account", account)
        payload.put("folder", folder)
        payload.put("shareWith", docType)
        payload.put("isUpdate", isUpdate)
        payload.put("appID", selectedAppID)
        payload.put("compID", selectedCompID)
        if (existingDocumentID != null) {
            payload.put("documentID", existingDocumentID)
        }
        if (existingDocumentTypeID != null) {
            payload.put("documentTypeID", existingDocumentTypeID)
        }
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


