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
    private var currentDocuments: List<ServiceDocument> = emptyList()
    private lateinit var ddDocType: MaterialAutoCompleteTextView
    private lateinit var ddProject: MaterialAutoCompleteTextView
    private lateinit var ddCompany: MaterialAutoCompleteTextView
    private var existingDocumentID: Int? = null
    private var existingDocumentTypeID: Int? = null
    private var selectedServiceID: Int? = null
    private var selectedAppID: Int = 0
    private var selectedCompID: Int = 0
    private var selectedCompanyName: String = ""
    private var userToken: String = ""
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)

        // Token'ı al
        userToken = prefs.getString("UserToken", "") ?: ""
        
        if (userToken.isEmpty()) {
            // Token yoksa hata göster ve kapat
            showErrorAndFinish("Lütfen önce Arti Capital uygulamasından giriş yapın.")
            return
        }

        val companies = (prefs.getString("Companies", "") ?: "")
            .split("|")
            .filter { it.isNotBlank() }
        
        // CompaniesWithIDs'den firma-ID eşleştirmesini al
        val companiesWithIDsString = prefs.getString("CompaniesWithIDs", "") ?: ""
        companyToCompIDMap = parseCompaniesWithIDs(companiesWithIDsString)
        
        val userRank = prefs.getString("UserRank", "") ?: ""
        val isAdmin = userRank == "50"

        // BottomSheetDialog ile ayrıntılı seçim
        val sheet = BottomSheetDialog(this)
        val view = LayoutInflater.from(this).inflate(R.layout.dialog_share_bottom_sheet, null)
        sheet.setContentView(view)

        ddCompany = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddCompany)
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

        // Company adapter - İlk seçim yapılmamış olarak başla
        val companyList = if (companies.isEmpty()) listOf("Seçiniz") else companies
        ddCompany.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, companyList))
        ddCompany.setText("Seçiniz", false)
        selectedCompanyName = ""

        // Projeler ve belgeler başlangıçta devre dışı
        ddProject.isEnabled = false
        ddDocType.isEnabled = false
        ddProject.setText("Firma seçiniz", false)
        ddDocType.setText("Seçiniz", false)

        // Firma seçimi değiştiğinde projeleri API'den yükle
        ddCompany.setOnItemClickListener { _, _, position, _ ->
            val selectedCompany = companyList[position]
            if (selectedCompany != "Seçiniz") {
                selectedCompanyName = selectedCompany
                selectedCompID = companyToCompIDMap[selectedCompany] ?: 0
                
                if (selectedCompID > 0) {
                    // Firma seçildi, projeleri yükle
                    loadingView?.visibility = View.VISIBLE
                    ddProject.isEnabled = false
                    ddDocType.isEnabled = false
                    
                    scope.launch {
                        try {
                            fetchProjectsForCompany(selectedCompID)
                            
                            withContext(Dispatchers.Main) {
                                loadingView?.visibility = View.GONE
                                ddProject.isEnabled = true
                                
                                // Projeleri listele
                                val projectNames = filteredServices.map { it.serviceName }
                                ddProject.setAdapter(ArrayAdapter(this@ShareActivity, android.R.layout.simple_list_item_1, projectNames))
                                
                                if (projectNames.isNotEmpty()) {
                                    // İlk projeyi seç ve belge türlerini yükle
                                    val firstService = filteredServices.first()
                                    ddProject.setText(projectNames.first(), false)
                                    selectedServiceID = firstService.serviceID
                                    selectedAppID = firstService.appID
                                    selectedCompID = firstService.compID
                                    
                                    // Proje detayını çek
                                    fetchProjectDetail(selectedAppID, btnProject, btnUpdate)
                                } else {
                                    ddProject.setText("Proje bulunamadı", false)
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                loadingView?.visibility = View.GONE
                                ddProject.isEnabled = true
                                ddProject.setText("Yükleme hatası", false)
                            }
                        }
                    }
                }
            } else {
                // "Seçiniz" seçildi, her şeyi sıfırla
                selectedCompanyName = ""
                selectedCompID = 0
                filteredServices = emptyList()
                ddProject.isEnabled = false
                ddDocType.isEnabled = false
                ddProject.setText("Firma seçiniz", false)
                ddDocType.setText("Seçiniz", false)
            }
        }

        // Proje seçilince proje detayını çek ve belge türlerini güncelle
        ddProject.setOnItemClickListener { _, _, position, _ ->
            if (position < filteredServices.size) {
                val selectedService = filteredServices[position]
                selectedServiceID = selectedService.serviceID
                selectedAppID = selectedService.appID
                selectedCompID = selectedService.compID
                
                // Proje detayını çek
                loadingView?.visibility = View.VISIBLE
                scope.launch {
                    try {
                        fetchProjectDetail(selectedAppID, btnProject, btnUpdate)
                        withContext(Dispatchers.Main) {
                            loadingView?.visibility = View.GONE
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            loadingView?.visibility = View.GONE
                        }
                    }
                }
            }
        }

        // Belge türü seçilince buton durumunu güncelle
        ddDocType.setOnItemClickListener { _, _, position, _ ->
            if (position < currentDocuments.size) {
                val selectedDoc = currentDocuments[position]
                
                // isAdded durumuna göre buton metni güncelle
                if (selectedDoc.isAdded) {
                    btnProject.visibility = View.GONE
                    btnUpdate.visibility = View.VISIBLE
                    btnUpdate.text = "Belgeyi Güncelle"
                    
                    // Mevcut belgenin documentID'sini bul
                    if (selectedAppID > 0) {
                        checkExistingDocument(selectedAppID, selectedCompID, position, btnProject, btnUpdate)
                    }
                } else {
                    btnProject.visibility = View.VISIBLE
                    btnUpdate.visibility = View.GONE
                    btnProject.text = "Belgeyi Yükle"
                    existingDocumentID = null
                    existingDocumentTypeID = null
                }
            }
        }

        btnProject.setOnClickListener {
            val account = selectedCompanyName
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "project", account = account, folder = folder, docType = docType, note = note, isUpdate = false)
            sheet.dismiss()
        }
        btnUpdate.setOnClickListener {
            val account = selectedCompanyName
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: "")
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "project", account = account, folder = folder, docType = docType, note = note, isUpdate = true)
            sheet.dismiss()
        }
        btnMessage.setOnClickListener {
            val account = selectedCompanyName
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

    private fun parseCompaniesWithIDs(jsonString: String): Map<String, Int> {
        if (jsonString.isEmpty()) return emptyMap()
        
        return try {
            val jsonArray = JSONArray(jsonString)
            val map = mutableMapOf<String, Int>()
            
            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)
                val compName = jsonObject.optString("compName", "")
                val compID = jsonObject.optInt("compID", 0)
                
                if (compName.isNotBlank() && compID > 0) {
                    map[compName] = compID
                }
            }
            
            map
        } catch (e: Exception) {
            emptyMap()
        }
    }

    private fun showErrorAndFinish(message: String) {
        androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle("Hata")
            .setMessage(message)
            .setPositiveButton("Tamam") { _, _ ->
                setResult(Activity.RESULT_CANCELED)
                finish()
            }
            .setCancelable(false)
            .show()
    }

    private suspend fun fetchProjectsForCompany(compID: Int) = withContext(Dispatchers.IO) {
        val url = "https://api.office701.com/arti-capital/service/user/account/projects/all?userToken=$userToken&compID=$compID"
        val credentials = Credentials.basic("Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM", "vRParTCAqTjtmkI17I1EVpPH57Edl0")
        
        val request = Request.Builder()
            .url(url)
            .header("Authorization", credentials)
            .header("Accept", "application/json")
            .get()
            .build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) {
            throw Exception("Projects API Error: ${response.code}")
        }

        val body = response.body?.string() ?: throw Exception("Empty projects response")
        val json = JSONObject(body)
        
        // API hata kontrolü
        val success = json.optBoolean("success", false)
        if (!success) {
            val message = json.optString("message", "Bilinmeyen hata")
            throw Exception(message)
        }
        
        val dataObj = json.optJSONObject("data") ?: throw Exception("No data object")
        val projectsArray = dataObj.optJSONArray("projects") ?: JSONArray()

        val services = mutableListOf<ServiceItem>()
        
        for (i in 0 until projectsArray.length()) {
            val projectObj = projectsArray.getJSONObject(i)
            val appID = projectObj.optInt("appID", 0)
            val projectCompID = projectObj.optInt("compID", 0)
            val appTitle = projectObj.optString("appTitle", "").trim()
            val appCode = projectObj.optString("appCode", "").trim()
            val compName = projectObj.optString("compName", "").trim()
            
            if (appTitle.isBlank() || appID == 0) continue
            
            // Servis listesine ekle (belgeler proje detayından gelecek)
            services.add(ServiceItem(
                serviceID = 0, // ServiceID artık kullanılmıyor
                serviceName = appTitle,
                documents = emptyList(), // Başlangıçta boş, proje detayından gelecek
                appID = appID,
                compID = projectCompID
            ))
        }
        
        filteredServices = services
    }

    private suspend fun fetchProjectDetail(appID: Int, btnProject: Button, btnUpdate: Button) = withContext(Dispatchers.IO) {
        val url = "https://api.office701.com/arti-capital/service/user/account/projects/$appID?userToken=$userToken"
        val credentials = Credentials.basic("Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM", "vRParTCAqTjtmkI17I1EVpPH57Edl0")
        
        val request = Request.Builder()
            .url(url)
            .header("Authorization", credentials)
            .header("Accept", "application/json")
            .get()
            .build()

        val response = client.newCall(request).execute()
        if (!response.isSuccessful) {
            throw Exception("Project detail API Error: ${response.code}")
        }

        val body = response.body?.string() ?: throw Exception("Empty response")
        val json = JSONObject(body)
        
        // API hata kontrolü
        val success = json.optBoolean("success", false)
        if (!success) {
            val message = json.optString("message", "Bilinmeyen hata")
            throw Exception(message)
        }
        
        val dataObj = json.optJSONObject("data") ?: throw Exception("No data object")
        val projectObj = dataObj.optJSONObject("project") ?: throw Exception("No project object")
        
        // CompID ve CompAdrID'yi güncelle
        selectedCompID = projectObj.optInt("compID", 0)
        val compAdrID = projectObj.optInt("compAdrID", 0)
        
        // RequiredDocuments'ı al
        val requiredDocsArray = projectObj.optJSONArray("requiredDocuments") ?: JSONArray()
        val documents = mutableListOf<ServiceDocument>()
        
        for (i in 0 until requiredDocsArray.length()) {
            val docObj = requiredDocsArray.getJSONObject(i)
            val documentID = docObj.optInt("documentID", 0)
            val documentName = docObj.optString("documentName", "")
            val isRequired = docObj.optBoolean("isRequired", false)
            val isAdded = docObj.optBoolean("isAdded", false)
            
            if (documentName.isNotBlank()) {
                documents.add(ServiceDocument(documentID, documentName, isAdded))
            }
        }
        
        withContext(Dispatchers.Main) {
            currentDocuments = documents
            
            // Belge türü dropdown'ını güncelle
            val docNames = documents.map { it.documentName }
            ddDocType.setAdapter(ArrayAdapter(this@ShareActivity, android.R.layout.simple_list_item_1, docNames))
            
            if (documents.isNotEmpty()) {
                val firstDoc = documents.first()
                ddDocType.setText(firstDoc.documentName, false)
                ddDocType.isEnabled = true
                
                // İlk belge için buton durumunu ayarla
                if (firstDoc.isAdded) {
                    btnProject.visibility = View.GONE
                    btnUpdate.visibility = View.VISIBLE
                    btnUpdate.text = "Belgeyi Güncelle"
                    
                    // Mevcut belge ID'sini bul
                    checkExistingDocument(appID, selectedCompID, 0, btnProject, btnUpdate)
                } else {
                    btnProject.visibility = View.VISIBLE
                    btnUpdate.visibility = View.GONE
                    btnProject.text = "Belgeyi Yükle"
                    existingDocumentID = null
                    existingDocumentTypeID = null
                }
            } else {
                ddDocType.setText("Belge bulunamadı", false)
                ddDocType.isEnabled = false
            }
        }
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
        currentDocuments = service.documents
        
        val documentNames = currentDocuments.map { it.documentName }
        ddDocType.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, documentNames))
        if (documentNames.isNotEmpty()) {
            ddDocType.setText(documentNames.first(), false)
        } else {
            ddDocType.setText("", false)
        }
        ddDocType.isEnabled = documentNames.isNotEmpty()
        
        // Belge türü değişince mevcut belgeyi kontrol et
        existingDocumentID = null
        existingDocumentTypeID = null
    }

    private fun checkExistingDocument(appID: Int, compID: Int, documentPosition: Int, btnProject: Button, btnUpdate: Button) {
        if (documentPosition >= currentDocuments.size) return
        
        val document = currentDocuments[documentPosition]
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
                            btnProject.text = "Belgeyi Yükle"
                        }
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        existingDocumentID = null
                        existingDocumentTypeID = null
                        btnProject.visibility = View.VISIBLE
                        btnUpdate.visibility = View.GONE
                        btnProject.text = "Belgeyi Yükle"
                    }
                }
            }
        } else {
            // Belge eklenmemiş, yeni kayıt
            existingDocumentID = null
            existingDocumentTypeID = null
            btnProject.visibility = View.VISIBLE
            btnUpdate.visibility = View.GONE
            btnProject.text = "Belgeyi Yükle"
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

    @Deprecated("No longer needed")
    private suspend fun checkDocumentExists(serviceID: Int, documentID: Int): Boolean = withContext(Dispatchers.IO) {
        false
    }

    @Deprecated("No longer used - projects loaded per company with user token")
    private suspend fun fetchAllServices(): Pair<List<ServiceItem>, Map<String, Int>> = withContext(Dispatchers.IO) {
        Pair(emptyList(), emptyMap())
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


