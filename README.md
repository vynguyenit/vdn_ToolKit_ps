# vdn ToolKit

**vdn ToolKit** la bo cong cu quan tri he thong Windows toan dien, duoc viet bang PowerShell, cho phep ban kiem tra thong tin phan cung, quan ly ban quyen Windows va Office, cai dat phan mem hang loat, toi uu hieu suat va xuat bao cao chi trong vai thao tac.

---

## Tinh nang

- **Thong tin he thong**: Hien thi ten may, domain, OS, CPU, RAM, dung luong o dia.
- **Ban quyen Windows**: Kiem tra Edition, trang thai kich hoat, loai license, key cuoi.
- **Ban quyen Office**: Hien thi tom tat cho cac phien ban Office 2010, 2013, 2016, 2019, 365.
- **Kich hoat Windows/Office**: Su dung key KMS mac dinh (co the tuy chinh).
- **Xoa ban quyen**: Go sach key Windows va Office khoi he thong (co xac nhan).
- **Cai dat phan mem**: Ho tro winget hoac tai truc tiep va cai silent.
- **Toi uu he thong**: Don rac, toi uu mang, hieu suat, tat dich vu, xoa cache Windows Update, toi uu o dia (SSD TRIM/HDD NTFS), tat Hibernate.
- **Quan ly may in**: Xoa sach may in hoac mo Print Management.
- **Xuat bao cao HTML**: Luu bao cao tong hop vao thu muc Documents.

---

## Yeu cau

- Windows 10/11 (phien ban 1809 tro len).
- Quyen Administrator (tu dong yeu cau neu chua co).
- Ket noi Internet de tai script va cau hinh (lan dau chay).
- Winget (khuyen nghich) de cai dat phan mem.

---

## Cach chay

Mo **PowerShell** voi quyen Administrator va nhap lenh:

```powershell
irm https://raw.githubusercontent.com/vynguyenit/vnd_ToolKit_ps/main/vdn_ToolKit.ps1 | iex
