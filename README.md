# Sfixx x OSINT

> Termux OSINT Toolkit — ringan, modular, dan legal. Fokus pada informasi publik.

Sfixx x OSINT adalah toolkit CLI sederhana yang dirancang untuk berjalan di **Termux (Android)**. Dibuat dengan **Bash** sebagai inti, ditambah **Python standard library** untuk parsing. Semua modul terpisah, sehingga mudah ditambah atau diperbaiki.

---

## Fitur

| # | Modul | Deskripsi |
|---|-------|-----------|
| 1 | Username Search | Cek keberadaan username di situs publik |
| 2 | Domain Information | WHOIS / RDAP domain |
| 3 | DNS Lookup | A, AAAA, MX, NS, TXT, CNAME, SOA |
| 4 | IP Information | Geolokasi & info IP via ipinfo.io |
| 5 | HTTP Headers | Header HTTP + security header check |
| 6 | Subdomain Discovery | Via Certificate Transparency (crt.sh) |
| 7 | URL Analyzer | Parse URL, response, indikator mencurigakan |
| 8 | System / Network Info | Info sistem & jaringan Termux |

---

## Contoh Penggunaan

**Menu interaktif:**
```bash
sfixx
```

**Command line langsung:**
```bash
sfixx username sfixx
sfixx domain example.com
sfixx dns example.com
sfixx ip 8.8.8.8
sfixx headers https://example.com
sfixx subdomain example.com
sfixx url https://example.com/path?q=1
sfixx system
sfixx update
```

**Contoh output:**
```
[*] Starting Sfixx x OSINT...
[*] Checking dependencies...
[+] Loading modules...
[✓] Ready.

Sfixx > 4
Masukkan IP / domain : 8.8.8.8
[*] Mengambil informasi untuk IP: 8.8.8.8
{
  "ip": "8.8.8.8",
  "city": "Mountain View",
  "region": "California",
  "country": "US",
  ...
}
```

---

## Requirements

- **Termux** (Android) — wajib
- `git`
- `curl`
- `python` (untuk parsing JSON)
- `dnsutils` (opsional, untuk `dig`/`nslookup`)
- `whois` (opsional, untuk WHOIS domain)

Semua dependency di atas **otomatis diinstal oleh `install.sh`**.

---

## Instalasi di Termux

```bash
pkg update && pkg upgrade
pkg install git
git clone https://github.com/YOUR_USERNAME/sfixx-osint.git
cd sfixx-osint
chmod +x install.sh
./install.sh
```

Setelah selesai:
```bash
sfixx
```

---

## Update

Lewat CLI:
```bash
sfixx update
```

Atau manual:
```bash
cd sfixx-osint
./update.sh
```

`update.sh` akan mengambil versi terbaru dari GitHub **tanpa menghapus `config/config.conf` milikmu**.

---

## Uninstall

```bash
cd sfixx-osint
bash uninstall.sh
```

Lalu hapus direktori project:
```bash
cd ..
rm -rf sfixx-osint
```

---

## Struktur Project

```
sfixx-osint/
├── sfixx                 # CLI utama
├── install.sh            # Installer Termux
├── uninstall.sh          # Uninstaller
├── update.sh             # Auto-update dari GitHub
├── requirements.txt
├── README.md
├── LICENSE
├── .gitignore
├── config/
│   └── config.conf       # Konfigurasi (VERSION, REPO_URL, TIMEOUT)
├── modules/
│   ├── username.sh
│   ├── domain.sh
│   ├── dns.sh
│   ├── ip.sh
│   ├── headers.sh
│   ├── subdomain.sh
│   ├── url.sh
│   └── system.sh
└── assets/
    └── banner.sh
```

Setiap modul mengekspor satu fungsi `xxx_main <arg>` dan dipanggil oleh CLI utama.

---

## Menambah Modul Baru

1. Buat file di `modules/` misal `modules/whoami.sh`:
   ```bash
   #!/usr/bin/env bash
   whoami_main() {
       echo "Hello $1"
   }
   ```
2. Tambahkan case di `sfixx` pada fungsi `dispatch()` dan `interactive_arg()`.
3. Update menu interaktif di `main_menu()`.

---

## Dependency

| Package | Fungsi | Wajib |
|---------|--------|-------|
| `git` | Clone & update repo | ✅ |
| `curl` | HTTP request ke API publik | ✅ |
| `python` | Parsing JSON | ✅ |
| `dnsutils` | `dig` / `nslookup` untuk modul DNS | Opsional |
| `whois` | WHOIS lookup domain | Opsional |

---

## Testing Setiap Fitur

```bash
# 1. Username search
sfixx username torvalds

# 2. Domain information
sfixx domain example.com

# 3. DNS lookup
sfixx dns github.com

# 4. IP information
sfixx ip 1.1.1.1
sfixx ip google.com

# 5. HTTP headers
sfixx headers https://github.com

# 6. Subdomain discovery
sfixx subdomain hackerone.com

# 7. URL analyzer
sfixx url https://bit.ly/abcdef

# 8. System info
sfixx system

# Menu interaktif
sfixx
```

---

## Legal & Disclaimer

Tool ini dibuat **hanya untuk tujuan edukasi dan riset keamanan yang legal**.

- Semua data yang diambil berasal dari sumber **publik** (WHOIS, DNS, Certificate Transparency, API publik).
- Tool ini **tidak** melakukan brute-force, bypass autentikasi, atau pengambilan data pribadi non-publik.
- **Jangan** gunakan tool ini untuk aktivitas ilegal, harassment, atau melanggar Terms of Service situs target.
- Pengguna bertanggung jawab penuh atas penggunaan tool ini.

Dengan menggunakan tool ini, kamu setuju bahwa pembuat tidak bertanggung jawab atas penyalahgunaan.

---

## License

MIT — lihat [LICENSE](LICENSE).