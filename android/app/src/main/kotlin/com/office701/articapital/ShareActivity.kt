package com.office701.articapital

import android.app.Activity
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.widget.ArrayAdapter
import android.widget.Button
import com.google.android.material.textfield.MaterialAutoCompleteTextView
import com.google.android.material.textfield.TextInputEditText
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.bottomsheet.BottomSheetDialog
import org.json.JSONArray
import org.json.JSONObject

class ShareActivity : AppCompatActivity() {

    private val prefsName = "group.com.office701.articapital"

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

        val projects = listOf("Tümü", "Ar-Ge", "Ür-Ge", "İstihdam", "İhracat")
        val docTypes = listOf(
            "Vergi Levhası","Faaliyet Belgesi","İmza Sirküleri","Ticaret Sicil Gazetesi",
            "Banka Dekontu","Sözleşme","Fatura","İrsaliye","Teklif/Form",
            "Proje Başvuru Formu","Destek Karar Yazısı","Taahhütname","Kimlik Fotokopisi","Yetki Belgesi"
        )

        // Hızlı seçimler: sadece iki seçenek gösterelim (Projeye Kaydet / Mesaj olarak gönder)
        // Detaylı seçimler (firma/proje/belge türü) için varsayılanları kullanıyoruz
        // BottomSheetDialog ile ayrıntılı seçim
        val sheet = BottomSheetDialog(this)
        val view = LayoutInflater.from(this).inflate(R.layout.dialog_share_bottom_sheet, null)
        sheet.setContentView(view)

        val ddCompany = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddCompany)
        val ddProject = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddProject)
        val ddDocType = view.findViewById<MaterialAutoCompleteTextView>(R.id.ddDocType)
        val etNote = view.findViewById<TextInputEditText>(R.id.etNote)
        val btnProject = view.findViewById<Button>(R.id.btnProject)
        val btnMessage = view.findViewById<Button>(R.id.btnMessage)

        // Admin ise tek seçenek: Mesaj
        if (isAdmin) {
            btnProject.visibility = android.view.View.GONE
        }

        // Adapters (Material dropdown)
        val companyList = if (companies.isEmpty()) listOf(accountNameDefault) else companies
        ddCompany.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, companyList))
        ddProject.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, projects))
        ddDocType.setAdapter(ArrayAdapter(this, android.R.layout.simple_list_item_1, docTypes))

        // Defaults
        ddCompany.setText(accountNameDefault, false)
        ddProject.setText(projects.first(), false)
        ddDocType.setText(docTypes.first(), false)

        btnProject.setOnClickListener {
            val account = (ddCompany.text?.toString()?.takeIf { it.isNotBlank() } ?: accountNameDefault)
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: projects.first())
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: docTypes.first())
            val note = etNote.text?.toString()?.trim().orEmpty()
            handleShare(mode = "project", account = account, folder = folder, docType = docType, note = note)
            sheet.dismiss()
        }
        btnMessage.setOnClickListener {
            val account = (ddCompany.text?.toString()?.takeIf { it.isNotBlank() } ?: accountNameDefault)
            val folder = (ddProject.text?.toString()?.takeIf { it.isNotBlank() } ?: projects.first())
            val docType = (ddDocType.text?.toString()?.takeIf { it.isNotBlank() } ?: docTypes.first())
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


