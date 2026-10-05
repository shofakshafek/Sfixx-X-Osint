#!/usr/bin/env bash
# ================================================
# Sfixx x OSINT - Phone Number Module (v2)
# Cek: validasi, format, operator, tipe, wilayah, link WhatsApp
# Opsi: --json (output JSON) | --offline (tanpa jaringan)
# ================================================

phone_main() {
    local phone="" json=0 offline=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --json)    json=1 ;;
            --offline) offline=1 ;;
            -h|--help)
                echo "  Pemakaian: sfixx phone <nomor> [--json] [--offline]"
                echo "  Contoh   : sfixx phone 081234567890"
                return 0 ;;
            *) phone="$1" ;;
        esac
        shift
    done

    if [ -z "$phone" ]; then
        log_err "Nomor telepon wajib diisi."
        echo "  Contoh: sfixx phone 081234567890"
        return 1
    fi

    if ! require_cmd python3; then
        log_err "Python3 wajib untuk modul ini."
        return 1
    fi

    # Koneksi hanya dibutuhkan untuk cek link WhatsApp
    if [ "$offline" -eq 0 ] && ! check_internet; then
        log_warn "Tidak ada koneksi, lanjut mode offline." 2>/dev/null || true
        offline=1
    fi

    [ "$json" -eq 0 ] && { log_info "Menganalisa nomor: ${C_YELLOW}$phone${C_RESET}"; echo; }

    SFIXX_PHONE="$phone" SFIXX_JSON="$json" SFIXX_OFFLINE="$offline" python3 << 'PYEOF'
import os, sys, re, json, urllib.request

raw     = os.environ.get("SFIXX_PHONE", "").strip()
AS_JSON = os.environ.get("SFIXX_JSON") == "1"
OFFLINE = os.environ.get("SFIXX_OFFLINE") == "1"
TIMEOUT = 10
UA = {"User-Agent": "Mozilla/5.0 (Termux; Sfixx-OSINT)"}

# ---------------- Helper ----------------
def digits_only(n):
    return re.sub(r"\D", "", n)

def normalize(n):
    """Kembalikan (digit_internasional, is_indonesia).
    Aturan: '+' atau '00' = sudah internasional; '0' = lokal Indonesia;
    '8xxx' (tanpa 0) = HP Indonesia; selain itu dianggap internasional apa adanya."""
    plus = n.strip().startswith("+")
    d = digits_only(n)
    if d.startswith("00"):
        d, plus = d[2:], True
    if plus:
        return d, d.startswith("62")
    if d.startswith("62"):
        return d, True
    if d.startswith("0"):
        return "62" + d[1:], True
    if d.startswith("8"):
        return "62" + d, True
    return d, False

result = {"input": raw}

# ---------------- Validasi dasar ----------------
d = digits_only(raw)
if len(d) < 8 or len(d) > 15:
    msg = "Nomor tidak valid (panjang harus 8-15 digit)."
    print(json.dumps({"error": msg}) if AS_JSON else f"  [x] {msg}")
    sys.exit(1)

intl, is_id = normalize(raw)
result.update({"digits": d, "e164": "+" + intl, "indonesia": is_id})

# ---------------- Operator Indonesia ----------------
OPERATORS = {
    "Telkomsel":       ["811","812","813","821","822","823","851","852","853"],
    "Indosat Ooredoo": ["814","815","816","855","856","857","858"],
    "XL Axiata":       ["817","818","819","859","877","878"],
    "AXIS":            ["831","832","833","838"],
    "Tri (3)":         ["895","896","897","898","899"],
    "Smartfren":       ["881","882","883","884","885","886","887","888","889"],
}
PREFIX2OP = {p: op for op, ps in OPERATORS.items() for p in ps}

# ---------------- Kode area telepon rumah (longest-prefix match) ----------------
AREA = {
    "21": "Jakarta & sekitarnya (DKI Jakarta)",
    "22": "Bandung (Jawa Barat)",
    "24": "Semarang (Jawa Tengah)",
    "31": "Surabaya (Jawa Timur)",
    "61": "Medan (Sumatera Utara)",
    "251": "Bogor (Jawa Barat)",
    "231": "Cirebon (Jawa Barat)",
    "254": "Serang (Banten)",
    "271": "Surakarta/Solo (Jawa Tengah)",
    "274": "Yogyakarta (DIY)",
    "341": "Malang (Jawa Timur)",
    "361": "Denpasar (Bali)",
    "370": "Mataram (NTB)",
    "380": "Kupang (NTT)",
    "401": "Kendari (Sulawesi Tenggara)",
    "411": "Makassar (Sulawesi Selatan)",
    "431": "Manado (Sulawesi Utara)",
    "435": "Gorontalo (Gorontalo)",
    "451": "Palu (Sulawesi Tengah)",
    "511": "Banjarmasin (Kalimantan Selatan)",
    "536": "Palangkaraya (Kalimantan Tengah)",
    "541": "Samarinda (Kalimantan Timur)",
    "542": "Balikpapan (Kalimantan Timur)",
    "551": "Tarakan (Kalimantan Utara)",
    "561": "Pontianak (Kalimantan Barat)",
    "711": "Palembang (Sumatera Selatan)",
    "717": "Pangkalpinang (Bangka Belitung)",
    "721": "Bandar Lampung (Lampung)",
    "736": "Bengkulu (Bengkulu)",
    "741": "Jambi (Jambi)",
    "751": "Padang (Sumatera Barat)",
    "761": "Pekanbaru (Riau)",
    "771": "Tanjung Pinang (Kepulauan Riau)",
    "778": "Batam (Kepulauan Riau)",
    "911": "Ambon (Maluku)",
    "921": "Ternate (Maluku Utara)",
    "951": "Sorong (Papua Barat Daya)",
    "967": "Jayapura (Papua)",
    "971": "Merauke (Papua Selatan)",
}

def match_area(rest):
    for L in (3, 2):
        if rest[:L] in AREA:
            return rest[:L], AREA[rest[:L]]
    return None, None

def out(label, value):
    print(f"  {label:<16}: {value}")

# ---------------- libphonenumber (opsional) ----------------
lib = {}
try:
    import phonenumbers
    from phonenumbers import geocoder, carrier, timezone, PhoneNumberType as T
    pn = phonenumbers.parse("+" + intl, None)
    lib["valid"] = phonenumbers.is_valid_number(pn)
    lib["possible"] = phonenumbers.is_possible_number(pn)
    lib["region"] = phonenumbers.region_code_for_number(pn)
    lib["country"] = geocoder.country_name_for_number(pn, "id") or None
    lib["geo"] = geocoder.description_for_number(pn, "id") or None
    lib["carrier"] = carrier.name_for_number(pn, "id") or None
    lib["timezones"] = list(timezone.time_zones_for_number(pn))
    lib["intl_fmt"] = phonenumbers.format_number(pn, phonenumbers.PhoneNumberFormat.INTERNATIONAL)
    lib["nat_fmt"] = phonenumbers.format_number(pn, phonenumbers.PhoneNumberFormat.NATIONAL)
    tmap = {T.MOBILE: "Seluler", T.FIXED_LINE: "Telepon rumah (landline)",
            T.FIXED_LINE_OR_MOBILE: "Landline / Seluler", T.TOLL_FREE: "Toll free",
            T.VOIP: "VoIP", T.PREMIUM_RATE: "Premium rate", T.SHARED_COST: "Shared cost",
            T.PERSONAL_NUMBER: "Personal", T.PAGER: "Pager", T.UAN: "UAN",
            T.VOICEMAIL: "Voicemail", T.UNKNOWN: "Tidak diketahui"}
    lib["type"] = tmap.get(phonenumbers.number_type(pn), "Tidak diketahui")
except ImportError:
    lib = None
except Exception as e:
    lib = {"error": str(e)}

# ---------------- Analisa ----------------
operator = brand_prefix = None
number_type = "Tidak diketahui"
area_code = area_name = None

if is_id:
    rest = intl[2:]
    if rest.startswith("8"):
        number_type = "Seluler (Mobile)"
        brand_prefix = "0" + rest[:3]
        operator = PREFIX2OP.get(rest[:3])
    else:
        area_code, area_name = match_area(rest)
        number_type = "Telepon rumah (Landline)" if area_name else "Tidak dapat diklasifikasi"
elif lib and "type" in lib:
    number_type = lib["type"]

result.update({
    "type": number_type, "operator": operator, "prefix": brand_prefix,
    "area_code": ("0" + area_code) if area_code else None,
    "area_name": area_name,
})

# ---------------- Link WhatsApp ----------------
# wa.me selalu merespon 200 untuk nomor apa pun, jadi TIDAK bisa dipakai
# memastikan nomor terdaftar. Modul ini hanya membuat link untuk dibuka manual.
wa_link = f"https://wa.me/{intl}"
result["whatsapp_link"] = wa_link

if lib and "valid" in lib:
    result["libphonenumber"] = lib

if AS_JSON:
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0)

# ---------------- Output teks ----------------
print("  --- Format ---")
out("Nomor Asli", raw)
out("Nomor Bersih", d)
out("E.164", "+" + intl)
if lib and "intl_fmt" in lib:
    out("Internasional", lib["intl_fmt"])
    out("Nasional", lib["nat_fmt"])
    out("Valid", "Ya" if lib["valid"] else "Tidak (menurut libphonenumber)")
print()

print("  --- Identifikasi ---")
out("Negara", (lib or {}).get("country") or ("Indonesia" if is_id else "Tidak diketahui"))
out("Tipe", number_type)
if is_id and operator:
    out("Operator", operator)
    out("Prefix", brand_prefix)
elif is_id and brand_prefix:
    out("Operator", "Prefix tidak dikenal")
if lib and lib.get("carrier") and not operator:
    out("Carrier", lib["carrier"])
if lib and lib.get("timezones"):
    out("Zona Waktu", ", ".join(lib["timezones"]))
print()

print("  --- Kemungkinan Wilayah ---")
if is_id and area_name:
    out("Kode Area", "0" + area_code)
    out("Perkiraan Kota", area_name)
    print("  (Level kota/provinsi saja; bukan alamat rumah.)")
elif is_id and number_type.startswith("Seluler"):
    out("Wilayah", "Tidak dapat ditentukan")
    print("  Nomor seluler tidak terikat ke lokasi atau alamat.")
elif lib and lib.get("geo"):
    out("Wilayah", lib["geo"])
else:
    out("Wilayah", "Tidak diketahui")
print()

print("  --- WhatsApp ---")
out("Link", wa_link)
print("  Buka manual untuk melihat apakah chat bisa dimulai.")
print("  Pengecekan otomatis tidak akurat, jadi tidak dilakukan.")
print()

if lib is None:
    print("  Tip: pip install phonenumbers  (info valid/zona waktu/carrier)")
    print()

print("  --- Catatan ---")
print("  - Operator berdasarkan prefix; bisa berbeda jika nomor di-porting.")
print("  - Nomor telepon tidak menyimpan alamat. Klaim sebaliknya = scam.")
print("  - Gunakan hanya untuk edukasi & riset yang legal.")
PYEOF

    [ "$json" -eq 0 ] && { echo; log_done "Selesai."; }
}
