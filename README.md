![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)
![rank](https://make.fun/badge/roblox-brainrot-01/shinichibi/roblox-brainrot-01/rank.svg)
![reward](https://make.fun/badge/roblox-brainrot-01/shinichibi/roblox-brainrot-01/reward.svg)

Entered in the make.fun bounty [roblox-brainrot-01](https://make.fun/bounty/roblox-brainrot-01).

# Brainrot Bay: Tsunami Tycoon

A sunny island, a road full of wandering weirdos, and a wave with anger issues.

**Brainrot Bay** is a collect-and-earn tycoon. Absurd meme-born creatures — *brainrots* —
wander the island's central lane. Grab one, carry it home on your head, and set it on a
pad in your base, where it earns you cash every second, forever. Spend the cash on eggs
that hatch rarer and richer brainrots, fill your base, and when the sirens sing, *run*:
a giant tsunami sweeps the island every couple of minutes, and any brainrot caught
outside a base is lost to the sea. Other players are a hazard too — one tag and the
brainrot you are carrying slips right out of your hands.

## How to play

1. **Grab** — Wild brainrots wander the central lane. Walk up and use the prompt to pick
   one up; it rides on your head and slows you down a little.
2. **Deliver** — Carry it into *your* base (the plot with your name on the sign). It
   hops onto a free pad and starts earning. Bases hold 6 brainrots.
3. **Earn** — Every placed brainrot pays its $/s into your Cash, every second. Your
   income rate is always on screen, top-right.
4. **Hatch** — Buy eggs at the Egg Shop stand at the end of the lane, or from the
   EGG SHOP panel: Cracked Egg ($150), Golden Egg ($2,500), Void Egg ($40,000) — pricier
   eggs roll much better rarities. Hatched brainrots appear straight on a free pad.
5. **Sell** — Use the prompt on any placed brainrot to sell it back for half its value.
6. **Survive** — When the announcement counts down, get home. Inside your own base you
   are safe; outside it, the wave takes whatever you are carrying and bowls you over.
   Watch out for other players, too: a tag knocks your catch loose.
7. **Rebirth** — For $25,000 (then ×5 each time) wipe your cash and base to double ALL
   income, permanently. Progress saves automatically (cash, brainrots, rebirths).

## The cast

Sixteen original brainrots across six rarities — Common, Rare, Epic, Legendary, Mythic,
Secret — each built in code from primitive parts with its own colours and accessory, and
each wearing a floating label with its name, rarity and $/s. Any of them can hatch or
wander in **mutated**: Golden (×2.5 income), Diamond (×5), or the shimmering Rainbow
(×12), which cycles through every colour while it earns.

| Brainrot | Rarity | $/s |
| --- | --- | --- |
| Sir Wobbles | Common | 1 |
| Cap'n Crumb | Common | 2 |
| Noodle Knight | Common | 3 |
| DJ Pickle | Common | 4 |
| Turbo Toaster | Rare | 9 |
| Baron von Banana | Rare | 12 |
| Professor Pancake | Rare | 15 |
| Bubble Duck | Rare | 18 |
| Sir Bounces-a-Lot | Epic | 40 |
| Count Quackula | Epic | 55 |
| Major Moonpie | Epic | 75 |
| The Gilded Gnome | Legendary | 160 |
| Mecha Milkshake | Legendary | 220 |
| Emperor Eggplant III | Mythic | 500 |
| Cosmic Burrito | Mythic | 750 |
| The Forbidden Meatball | Secret | 2,000 |

## Under the hood

Everything is code — no external assets, no real-money anything. The whole world
(island, lane, 8 bases, egg shop, palms, sirens, the welcome arch) is built at runtime
by a server module, so the place file stays tiny and every part of the game lives in
`src/`:

- `src/shared/` — the brainrot catalogue (characters, rarities, mutations, eggs and
  their odds), the builder that composes each character from parts, money formatting.
- `src/server/` — one module per job: world building, plot assignment, the economy
  (income tick, eggs, selling, rebirth), wild brainrots (spawning, carrying, delivery),
  the threats (tsunami cycle, stealing), saving (DataStore with a Studio-safe fallback),
  and `Main`, which wires them together around one shared state table.
- `src/client/` — the whole interface built in code: stats, egg shop panel, collection
  index, rebirth panel, announcements, toasts and the carrying banner.

Build the place with [Rojo](https://rojo.space/): `rojo build default.project.json
--output game.rbxl`. `main.ts` is the hand-in program: it stages `game.rbxl`,
`PLAY.json`, `src/` and `screenshots/` into the output directory and writes the
`dossier.json` summary with the vendored make.fun library.

---

## Checklist publish (untuk pemilik akun Roblox)

Game ini sudah jadi dan ter-build sebagai `game.rbxl`. Agar bisa dimainkan publik dan
link-nya bisa diserahkan ke make.fun, game perlu di-publish dari akun Roblox kamu
sendiri lewat Roblox Studio. Langkahnya:

1. **Install / buka Roblox Studio**, lalu login dengan akun Roblox kamu.
2. **Buka file `game.rbxl`** dari repo ini (menu *File → Open from File*). Alternatif:
   sinkronkan folder repo dengan Rojo (*Rojo sync* dari `default.project.json`), tapi
   membuka `game.rbxl` langsung adalah cara paling sederhana.
3. **Publish:** menu *File → Publish to Roblox As…* → buat experience **baru** → beri
   nama **Brainrot Bay: Tsunami Tycoon** → *Create*, lalu *Publish*.
4. **Di Creator Dashboard** (create.roblox.com → experience yang baru dibuat):
   - **Deskripsi:** isi deskripsi singkat tentang game-nya. Jangan menulis teks yang
     menyerupai alamat web (misalnya mengandung "www" atau ".com") — Roblox bisa
     menolaknya. Tempel juga **play code** dari make.fun yang akan dikirimkan menyusul
     ke dalam deskripsi ini.
   - **Genre:** pilih genre yang cocok (misalnya *Simulation* / *Tycoon* bila tersedia).
   - **Kuesioner konten (Content Maturity / kuesioner):** jawab **No / Tidak** untuk
     semua pertanyaan konten khusus dewasa (tidak ada konten age-restricted di game
     ini).
   - **Jadikan Public:** di pengaturan akses (Access / *Configure Experience*), ubah
     visibilitas dari Private menjadi **Public**.
   - **Upload ikon** experience dan **thumbnail**: pakai file
     `screenshots/00-thumbnail.png` dari repo ini sebagai thumbnail (dan ikon bila
     diminta gambar terpisah, file yang sama bisa dipakai).
5. **Kirim balik ke ASPRI** empat hal ini:
   - **Link play** experience-nya (URL halaman game di roblox.com),
   - **place_id** dan **universe_id** (terlihat di Creator Dashboard / URL dashboard),
   - **3 screenshot dari dalam Studio / playtest**: (1) base yang sudah terisi brainrot
     sedang menghasilkan uang, (2) momen di toko telur / membeli telur, (3) lari pulang
     saat tsunami datang.

Setelah itu ASPRI yang mengisi `PLAY.json`, menambahkan screenshot ke repo, menjalankan
pengecekan terakhir, dan men-submit entri ke make.fun sebelum deadline.
