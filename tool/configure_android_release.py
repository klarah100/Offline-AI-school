#!/usr/bin/env python3
from pathlib import Path
import base64
import os

TARGET_SDK = "36"

def write_signing_material(android_dir: Path) -> bool:
    encoded = os.getenv("ANDROID_KEYSTORE_BASE64", "")
    if not encoded:
        return False

    required = [
        "ANDROID_KEYSTORE_PASSWORD",
        "ANDROID_KEY_ALIAS",
        "ANDROID_KEY_PASSWORD",
    ]
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise SystemExit("Missing Android signing secrets: " + ", ".join(missing))

    keystore = android_dir / "upload-keystore.jks"
    keystore.write_bytes(base64.b64decode(encoded))

    props = android_dir / "key.properties"
    props.write_text(
        "storePassword=" + os.environ["ANDROID_KEYSTORE_PASSWORD"] + "\n" +
        "keyPassword=" + os.environ["ANDROID_KEY_PASSWORD"] + "\n" +
        "keyAlias=" + os.environ["ANDROID_KEY_ALIAS"] + "\n" +
        "storeFile=../upload-keystore.jks\n"
    )
    return True

def configure_kts(path: Path, signing_ready: bool) -> None:
    text = path.read_text()
    text = text.replace("targetSdk = flutter.targetSdkVersion", f"targetSdk = {TARGET_SDK}")
    if signing_ready and "create("release")" not in text:
        signing_block = '''
    signingConfigs {
        create("release") {
            val keyProperties = java.util.Properties()
            val keyPropertiesFile = rootProject.file("key.properties")
            keyPropertiesFile.inputStream().use { keyProperties.load(it) }
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

'''
        text = text.replace("    buildTypes {", signing_block + "    buildTypes {", 1)
        text = text.replace(
            'signingConfig = signingConfigs.getByName("debug")',
            'signingConfig = signingConfigs.getByName("release")',
            1,
        )
    path.write_text(text)

def configure_groovy(path: Path, signing_ready: bool) -> None:
    text = path.read_text()
    text = text.replace("targetSdk flutter.targetSdkVersion", f"targetSdk {TARGET_SDK}")
    if signing_ready and "signingConfigs" not in text:
        signing_block = '''
    signingConfigs {
        release {
            def keystoreProperties = new Properties()
            def keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
            }
            keyAlias keystoreProperties["keyAlias"]
            keyPassword keystoreProperties["keyPassword"]
            storeFile keystoreProperties["storeFile"] ? file(keystoreProperties["storeFile"]) : null
            storePassword keystoreProperties["storePassword"]
        }
    }

'''
        text = text.replace("    buildTypes {", signing_block + "    buildTypes {", 1)
        text = text.replace(
            "signingConfig signingConfigs.debug",
            "signingConfig signingConfigs.release",
            1,
        )
    path.write_text(text)

android = Path("android")
if not android.exists():
    raise SystemExit("Run flutter create --platforms=android first.")

signing_ready = write_signing_material(android)
kts = android / "app" / "build.gradle.kts"
groovy = android / "app" / "build.gradle"

if kts.exists():
    configure_kts(kts, signing_ready)
elif groovy.exists():
    configure_groovy(groovy, signing_ready)
else:
    raise SystemExit("Android app Gradle file not found.")

print("Android target SDK configured to", TARGET_SDK)
print("Release signing:", "configured from secrets" if signing_ready else "not configured; CI will use the generated debug signing for build verification")
