package dk.carp.studies_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity

class PermissionsRationaleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val privacyPolicyUrl = "https://carp.dk/privacy-policy-app"
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(privacyPolicyUrl))
        startActivity(intent)

        finish() // Close the activity immediately after opening the link
    }
}