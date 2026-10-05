#!/usr/bin/env bash
# ================================================
# Sfixx x OSINT - Phone Number Module
# Cek: validasi nomor, operator, WhatsApp, wilayah
# Fokus: nomor Indonesia (+62) & internasional
# ================================================

phone_main() {
    local phone="$1"
    if [ -z "$phone" ]; then
        log_err "Nomor telepon wajib diisi."
        echo "  Contoh: sfixx phone 081234567890"
        return 1
    fi

    if ! check_internet; then
        log_err "Tidak ada koneksi internet."
        return 1
    fi

    if ! require_cmd python3; then
        log_err "Python3 wajib untuk modul ini."
        return 1
    fi

    log_info "Menganalisa nomor: ${C_YELLOW}$phone${C_RESET}"
    echo

    SFIXX_PHONE="$phone" python3 << 'PYEOF'
import os, sys, re, json, urllib.request

raw = os.environ.get("SFIXX_PHONE", "").strip()
TIMEOUT = 12

# ---------------- Helper ----------------
def fetch_json(url, headers=None):
    try:
        req = urllib.request.Request(url, headers=headers or {
            "User-Agent": "Mozilla/5.0 (Termux; Sfixx-OSINT)"
        })
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return json.loads(r.read().decode("utf-8", errors="ignore"))
    except Exception:
        return None

def clean_number(n):
    return re.sub(r"\D", "", n)

def to_intl(n):
    n = clean_number(n)
    if n.startswith("0"):
        n = "62" + n[1:]
    if not n.startswith("62") and len(n) <= 12:
        n = "62" + n
    return n

# ---------------- Validasi dasar ----------------
digits = clean_number(raw)
if len(digits) < 8 or len(digits) > 15:
    print("  [x] Nomor tidak valid (panjang harus 8-15 digit).")
    sys.exit(1)

is_id = digits.startswith("62") or digits.startswith("0")
intl = to_intl(raw)

print(f"  Nomor Asli      : {raw}")
print(f"  Nomor Bersih    : {digits}")
print(f"  Format Internl  : +{intl}")
print()

# ---------------- Mapping Operator Indonesia ----------------
OPERATOR_MAP = {
    # Telkomsel
    "0811": ("Telkomsel", "simPATI / Halo"),
    "0812": ("Telkomsel", "simPATI / Halo"),
    "0813": ("Telkomsel", "simPATI / Halo"),
    "0821": ("Telkomsel", "simPATI / Halo"),
    "0822": ("Telkomsel", "simPATI / Halo"),
    "0823": ("Telkomsel", "simPATI / Halo"),
    "0851": ("Telkomsel", "simPATI / Halo"),
    "0852": ("Telkomsel", "simPATI / Halo"),
    "0853": ("Telkomsel", "simPATI / Halo"),
    # Indosat Ooredoo
    "0814": ("Indosat Ooredoo", "IM3 / Mentari"),
    "0815": ("Indosat Ooredoo", "IM3 / Mentari"),
    "0816": ("Indosat Ooredoo", "IM3 / Mentari"),
    "0855": ("Indosat Ooredoo", "IM3 / Mentari"),
    "0856": ("Indosat Ooredoo", "IM3 / Mentari"),
    "0857": ("Indosat Ooredoo", "IM3 / Mentari"),
    "0858": ("Indosat Ooredoo", "IM3 / Mentari"),
    # XL Axiata
    "0817": ("XL Axiata", "XL / Axis"),
    "0818": ("XL Axiata", "XL / Axis"),
    "0819": ("XL Axiata", "XL / Axis"),
    "0859": ("XL Axiata", "XL / Axis"),
    "0877": ("XL Axiata", "XL / Axis"),
    "0878": ("XL Axiata", "XL / Axis"),
    # AXIS
    "0831": ("AXIS", "AXIS"),
    "0832": ("AXIS", "AXIS"),
    "0833": ("AXIS", "AXIS"),
    "0838": ("AXIS", "AXIS"),
    # Tri (3)
    "0895": ("Tri (3)", "3 (Tri)"),
    "0896": ("Tri (3)", "3 (Tri)"),
    "0897": ("Tri (3)", "3 (Tri)"),
    "0898": ("Tri (3)", "3 (Tri)"),
    "0899": ("Tri (3)", "3 (Tri)"),
    # Smartfren
    "0881": ("Smartfren", "Smartfren"),
    "0882": ("Smartfren", "Smartfren"),
    "0883": ("Smartfren", "Smartfren"),
    "0884": ("Smartfren", "Smartfren"),
    "0885": ("Smartfren", "Smartfren"),
    "0886": ("Smartfren", "Smartfren"),
    "0887": ("Smartfren", "Smartfren"),
    "0888": ("Smartfren", "Smartfren"),
    "0889": ("Smartfren", "Smartfren"),
}

# ---------------- Deteksi Operator ----------------
op_name = None
op_brand = None

if is_id:
    print("  --- Deteksi Operator (berdasarkan prefix) ---")
    if digits.startswith("62"):
        prefix4 = "0" + digits[2:5]
    else:
        prefix4 = digits[:4]

    if prefix4 in OPERATOR_MAP:
        op_name, op_brand = OPERATOR_MAP[prefix4]
        print(f"  Operator        : {op_name}")
        print(f"  Brand           : {op_brand}")
        print(f"  Prefix          : {prefix4}")
    else:
        print("  Operator        : Tidak terdeteksi (prefix tidak dikenal)")
    print()

# ---------------- Cek WhatsApp ----------------
print("  --- Cek WhatsApp ---")
wa_alt = f"https://wa.me/{intl}"
wa_status = None

try:
    req = urllib.request.Request(wa_alt, method="HEAD", headers={
        "User-Agent": "Mozilla/5.0 (Termux; Sfixx-OSINT)"
    })
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        code = r.getcode()
    if code in (200, 302):
        print(f"  Status          : OK Kemungkinan terdaftar di WhatsApp")
        wa_status = True
    else:
        print(f"  Status          : -- Tidak terdeteksi (kode {code})")
        wa_status = False
except Exception:
    print("  Status          : ?? Tidak bisa dicek (API tidak tersedia)")
print()

# ---------------- Info Tambahan (phonenumbers) ----------------
print("  --- Info Tambahan ---")
has_libphone = False
try:
    import phonenumbers
    from phonenumbers import geocoder, carrier, number_type, PhoneNumberType
    pn = phonenumbers.parse("+" + intl, None)
    if phonenumbers.is_valid_number(pn):
        has_libphone = True
        loc = geocoder.description_for_number(pn, "id") or "-"
        car = carrier.name_for_number(pn, "id") or "-"
        ntype = number_type(pn)
        type_map = {
            PhoneNumberType.MOBILE: "Mobile",
            PhoneNumberType.FIXED_LINE: "Fixed Line (Landline)",
            PhoneNumberType.FIXED_LINE_OR_MOBILE: "Fixed Line / Mobile",
            PhoneNumberType.TOLL_FREE: "Toll Free",
            PhoneNumberType.VOIP: "VoIP",
            PhoneNumberType.PREMIUM_RATE: "Premium Rate",
            PhoneNumberType.SHARED_COST: "Shared Cost",
            PhoneNumberType.PERSONAL_NUMBER: "Personal Number",
            PhoneNumberType.PAGER: "Pager",
            PhoneNumberType.UAN: "UAN",
            PhoneNumberType.VOICEMAIL: "Voicemail",
            PhoneNumberType.UNKNOWN: "Unknown",
        }
        print(f"  Negara          : {loc}")
        print(f"  Carrier         : {car}")
        print(f"  Tipe            : {type_map.get(ntype, 'Unknown')}")
    else:
        print("  Nomor           : Tidak valid menurut libphonenumber")
except ImportError:
    print("  (Install 'phonenumbers' untuk info lebih lengkap:")
    print("   pip install phonenumbers)")
except Exception as e:
    print(f"  Error parsing   : {e}")

if not has_libphone:
    print("  Negara          : Indonesia (asumsi dari prefix)")

print()

# ---------------- Kemungkinan Wilayah / Alamat ----------------
print("  --- Kemungkinan Wilayah ---")

AREA_CODE = {
    "21": "Jakarta, Bogor, Depok, Tangerang, Bekasi (Jabodetabek)",
    "22": "Bandung, Cimahi, Sumedang (Jawa Barat)",
    "23": "Cirebon, Indramayu, Majalengka, Kuningan (Jawa Barat)",
    "24": "Semarang, Salatiga, Demak, Kudus (Jawa Tengah)",
    "25": "Bogor (sebagian), Sukabumi, Cianjur (Jawa Barat)",
    "26": "Bandung (sebagian), Garut, Tasikmalaya (Jawa Barat)",
    "27": "Yogyakarta, Magelang, Solo (DIY & Jateng)",
    "28": "Purwokerto, Tegal, Pekalongan (Jawa Tengah)",
    "29": "Kudus, Jepara, Pati, Rembang (Jawa Tengah)",
    "31": "Surabaya, Gresik, Sidoarjo (Jawa Timur)",
    "32": "Malang, Pasuruan, Probolinggo (Jawa Timur)",
    "33": "Jember, Banyuwangi, Bondowoso (Jawa Timur)",
    "34": "Kediri, Blitar, Tulungagung (Jawa Timur)",
    "35": "Madiun, Ngawi, Ponorogo, Magetan (Jawa Timur)",
    "36": "Denpasar, Badung, Gianyar, Tabanan (Bali)",
    "37": "Mataram, Lombok (NTB)",
    "38": "Kupang, Flores, Sumba (NTT)",
    "41": "Makassar, Gowa, Maros (Sulawesi Selatan)",
    "42": "Palu, Donggala (Sulawesi Tengah)",
    "43": "Manado, Bitung, Tomohon (Sulawesi Utara)",
    "44": "Kendari, Bau-Bau (Sulawesi Tenggara)",
    "45": "Gorontalo (Gorontalo)",
    "46": "Ambon, Ternate (Maluku)",
    "51": "Banjarmasin, Martapura (Kalimantan Selatan)",
    "52": "Pontianak, Singkawang (Kalimantan Barat)",
    "53": "Palangkaraya, Sampit (Kalimantan Tengah)",
    "54": "Samarinda, Balikpapan, Bontang (Kalimantan Timur)",
    "55": "Tarakan, Nunukan (Kalimantan Utara)",
    "61": "Medan, Binjai, Deli Serdang (Sumatera Utara)",
    "62": "Pematang Siantar, Tebing Tinggi (Sumatera Utara)",
    "63": "Riau (sebagian), Kepulauan Riau",
    "64": "Pekanbaru, Dumai (Riau)",
    "65": "Jambi (Jambi)",
    "66": "Padang, Bukittinggi (Sumatera Barat)",
    "71": "Palembang, Prabumulih (Sumatera Selatan)",
    "72": "Bengkulu (Bengkulu)",
    "73": "Bandar Lampung, Metro (Lampung)",
    "74": "Jambi (sebagian), Riau (sebagian)",
    "75": "Padang (sebagian), Bukittinggi (Sumbar)",
    "76": "Pekanbaru (sebagian), Dumai (Riau)",
    "77": "Batam, Tanjung Pinang (Kepulauan Riau)",
    "81": "Jayapura, Merauke (Papua)",
    "90": "Papua (sebagian)",
    "91": "Papua (sebagian)",
    "92": "Papua (sebagian)",
    "93": "Papua (sebagian)",
}

OPERATOR_COVERAGE = {
    "Telkomsel": "Nasional (seluruh Indonesia)",
    "Indosat Ooredoo": "Nasional (seluruh Indonesia)",
    "XL Axiata": "Nasional (seluruh Indonesia)",
    "AXIS": "Nasional (seluruh Indonesia)",
    "Tri (3)": "Nasional (seluruh Indonesia)",
    "Smartfren": "Nasional (seluruh Indonesia)",
}

is_landline = False

if is_id:
    # Nomor Indonesia
    if digits.startswith("62"):
        rest = digits[2:]
    else:
        rest = digits[1:]

    # --- Cek apakah landline ---
    # Landline Indonesia: 0 + kode area (2 digit) + nomor lokal
    # Contoh: 021xxxxxxx (Jakarta), 022xxxxxxx (Bandung)
    # Nomor HP: 08xx (prefix 4 digit)
    if rest.startswith("8"):
        # Nomor seluler
        print(f"  Tipe Nomor      : Nomor Seluler (Mobile)")
        if op_name:
            print(f"  Operator        : {op_name}")
            print(f"  Cakupan         : {OPERATOR_COVERAGE.get(op_name, 'Tidak diketahui')}")
        print(f"  Wilayah Presisi : TIDAK DAPAT DITENTUKAN")
        print()
        print(f"  [!] CATATAN: Nomor HP TIDAK menyimpan alamat rumah.")
        print(f"      Operator tidak membagikan data lokasi ke publik.")
        print(f"      Untuk alamat presisi butuh akses resmi (polisi).")
    else:
        # Kemungkinan landline, ambil 2 digit pertama sebagai kode area
        area = rest[:2]
        if area in AREA_CODE:
            is_landline = True
            print(f"  Tipe Nomor      : Telepon Rumah (Landline)")
            print(f"  Kode Area       : 0{area}")
            print(f"  Perkiraan Kota  : {AREA_CODE[area]}")
        else:
            print(f"  Tipe Nomor      : Tidak dapat diklasifikasi")
            print(f"  Kode Area       : 0{area} (tidak ada di database)")
else:
    print(f"  Tipe Nomor      : Non-Indonesia")
    print(f"  Wilayah         : Di luar cakupan modul (hanya ID)")

print()

# ---------------- Reverse Lookup via Numverify-like (opsional) ----------------
# Beberapa API publik gratis bisa dipakai. Kalau butuh, aktifkan di sini.
# Contoh: https://apilayer.com/marketplace/number_verification-api
# Tidak diaktifkan default karena butuh API key.

# ---------------- Catatan ----------------
print("  --- Catatan ---")
print("  - Deteksi operator berdasarkan prefix; bisa berubah jika nomor")
print("    di-porting antar operator.")
print("  - Cek WhatsApp berbasis redirect publik; hasil bisa")
print("    false-positive/negative karena rate-limit.")
if not is_landline:
    print("  - Nomor HP TIDAK menyimpan alamat. Klaim sebaliknya = scam.")
print("  - Modul ini HANYA untuk edukasi & riset legal.")
PYEOF

    echo
    log_done "Selesai."
}
