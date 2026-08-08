markdown

\# vdn ToolKit

\*\*vdn ToolKit\*\* la bo cong cu quan tri he thong Windows toan dien, duoc viet bang PowerShell, cho phep ban kiem tra thong tin phan cung, quan ly ban quyen Windows va Office, cai dat phan mem hang loat, toi uu hieu suat va xuat bao cao chi trong vai thao tac.

\---

\## Tinh nang

\- \*\*Thong tin he thong\*\*: Hien thi ten may, domain, OS, CPU, RAM, dung luong o dia.

\- \*\*Ban quyen Windows\*\*: Kiem tra Edition, trang thai kich hoat, loai license, key cuoi.

\- \*\*Ban quyen Office\*\*: Hien thi tom tat cho cac phien ban Office 2010, 2013, 2016, 2019, 365.

\- \*\*Kich hoat Windows/Office\*\*: Su dung key KMS mac dinh (co the tuy chinh).

\- \*\*Xoa ban quyen\*\*: Go sach key Windows va Office khoi he thong (co xac nhan).

\- \*\*Cai dat phan mem\*\*: Ho tro winget hoac tai truc tiep va cai silent.

\- \*\*Toi uu he thong\*\*: Don rac, toi uu mang, hieu suat, tat dich vu, xoa cache Windows Update, toi uu o dia (SSD TRIM/HDD NTFS), tat Hibernate.

\- \*\*Quan ly may in\*\*: Xoa sach may in hoac mo Print Management.

\- \*\*Xuat bao cao HTML\*\*: Luu bao cao tong hop vao thu muc Documents.

\---

\## Yeu cau

\- Windows 10/11 (phien ban 1809 tro len).

\- Quyen Administrator (tu dong yeu cau neu chua co).

\- Ket noi Internet de tai script va cau hinh (lan dau chay).

\- Winget (khuyen nghich) de cai dat phan mem.

\---

\## Cach chay

Mo \*\*PowerShell\*\* voi quyen Administrator va nhap lenh:

\`\`\`powershell

irm https://raw.githubusercontent.com/vynguyenit/vnd\_ToolKit\_ps/main/vdn\_ToolKit.ps1 | iex

Hoac neu ban da tai file ve:

powershell

powershell -ExecutionPolicy Bypass -File .\\vdn\_ToolKit.ps1

Giao dien menu

Sau khi chay, menu chinh hien thi:

text

\==================================================

vdn ToolKit - He thong & Ban quyen

\==================================================

\[1\] Thong tin he thong

\[2\] Ban quyen Windows

\[3\] Ban quyen Office

\[4\] Kich hoat Windows (KMS)

\[5\] Kich hoat Office (KMS)

\[6\] Xoa ban quyen Windows (Nguy hiem)

\[7\] Xoa ban quyen Office (Nguy hiem)

\[8\] Cai dat phan mem (winget)

\[9\] Toi uu he thong (Optimizer)

\[A\] Quan ly may in

\[E\] Xuat bao cao HTML

\[H\] Huong dan su dung

\[0\] Thoat

\==================================================

Chon chuc nang \[1,2,3...A,E,H,0\]:

Chon so hoac ky tu tuong ung de thuc hien.

Cau hinh va tuy chinh

Thay doi Key KMS

Mo file vdn\_ToolKit.ps1, tim cac dong:

powershell

$key = "W269N-WFGWX-YVC9B-4J6C9-T83GX" # Windows

$key = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH" # Office

Thay bang key cua ban.

Them/bot phan mem

Chinh sua file config/software.json tren GitHub (hoac tai ve va sua). Cau truc:

json

{

"apps": \[

{"name": "Ten hien thi", "id": "winget-id", "url": ""},

{"name": "Khong co winget", "id": "", "url": "https://example.com/setup.exe"}

\]

}

id: ID tren winget (de trong neu khong dung).

url: Duong dan tai ve va cai silent (tham so mac dinh: /quiet /norestart).

Huong dan dong gop

Fork repository.

Tao nhanh moi (git checkout -b feature/your-feature).

Commit thay doi (git commit -m 'Add something').

Push len nhanh (git push origin feature/your-feature).

Tao Pull Request.

Giay phep

Duoc phan phoi theo MIT License.

Tac gia

Vy Nguyen – GitHub

Chuc ban su dung vdn ToolKit hieu qua!

text

\---

\## 🚀 Cách sử dụng cuối cùng

Người dùng chỉ cần mở \*\*PowerShell (Admin)\*\* và chạy:

\`\`\`powershell

irm https://raw.githubusercontent.com/vynguyenit/vnd\_ToolKit\_ps/main/vdn\_ToolKit.ps1 | iex

Script sẽ tự động tải về, chạy, và tự dọn dẹp sau khi thoát. Toàn bộ thông báo đều bằng tiếng Việt không dấu, giao diện rõ ràng, không nhắc đến bất kỳ dự án bên ngoài.

Bây giờ bạn có thể upload toàn bộ lên repository vnd\_ToolKit\_ps và sử dụng.