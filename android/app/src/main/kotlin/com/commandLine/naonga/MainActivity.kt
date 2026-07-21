package com.commandLine.naonga

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
	private val CHANNEL = "loan_tracker/share"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method == "shareFile") {
					val path = call.argument<String>("path")
					if (path != null) {
						shareFile(path)
						result.success(true)
					} else {
						result.error("NO_PATH", "No file path provided", null)
					}
				} else {
					result.notImplemented()
				}
			}
	}

	private fun shareFile(path: String) {
		val file = File(path)
		if (!file.exists()) return

		val uri: Uri = FileProvider.getUriForFile(
			this,
			applicationContext.packageName + ".fileprovider",
			file
		)

		val intent = Intent(Intent.ACTION_SEND).apply {
			type = "text/csv"
			putExtra(Intent.EXTRA_STREAM, uri)
			addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
		}

		startActivity(Intent.createChooser(intent, "Share CSV"))
	}
}
