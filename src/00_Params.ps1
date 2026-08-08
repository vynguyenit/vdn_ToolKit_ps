<#
.SYNOPSIS
    vdn ToolKit - Bo cong cu quan tri he thong Windows chuyen nghiep
.DESCRIPTION
    Hien thi thong tin, kiem tra ban quyen, kich hoat Windows/Office,
    cai dat phan mem, toi uu he thong, quan ly may in.
    Chay voi quyen Administrator. Ho tro ca giao dien menu va che do dong lenh (CLI).
.PARAMETER Action
    Hanh dong can thuc hien (SysInfo, WinLicense, OfficeLicense, ActivateWin, ActivateOffice, RemoveWinLic, RemoveOfficeLic, InstallApps, Optimize, CleanCarbonBlack, CleanPrinters).
.PARAMETER Apps
    Danh sach index phan mem can cai dat (cach nhau boi khoang trang), e.g. "1 3 5"
.PARAMETER TweakOption
    Lua chon toi uu (1-9), e.g. "8" de don dep CarbonBlack Store.
.PARAMETER Silent
    Chay che do khong hien thi hoi xac nhan.
#>

[CmdletBinding()]
param(
    [ValidateSet("SysInfo", "WinLicense", "OfficeLicense", "ActivateWin", "ActivateOffice", "RemoveWinLic", "RemoveOfficeLic", "InstallApps", "Optimize", "CleanCarbonBlack", "CleanPrinters")]
    [string]$Action,

    [string]$Apps,

    [ValidateSet("1", "2", "3", "4", "5", "6", "7", "8", "9")]
    [string]$TweakOption,

    [switch]$Silent
)
