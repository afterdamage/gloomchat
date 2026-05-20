# PowerShell script to replace remaining Material Icons with Font Awesome icons

$libDir = "c:\gloomchat\lib"

$files = Get-ChildItem -Path $libDir -Recurse -Filter "*.dart" | 
    Where-Object { (Get-Content $_.FullName -Raw) -match '\bIcons\.' }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    $content = $content -replace '\bIcons\.add_circle_outline\b', 'FontAwesomeIcons.circlePlus'
    $content = $content -replace '\bIcons\.add_link\b', 'FontAwesomeIcons.link'
    $content = $content -replace '\bIcons\.add_reaction_outlined\b', 'FontAwesomeIcons.faceSmile'
    $content = $content -replace '\bIcons\.arrow_drop_down\b', 'FontAwesomeIcons.caretDown'
    $content = $content -replace '\bIcons\.arrow_right\b', 'FontAwesomeIcons.arrowRight'
    $content = $content -replace '\bIcons\.attachment_outlined\b', 'FontAwesomeIcons.paperclip'
    $content = $content -replace '\bIcons\.audio_file_outlined\b', 'FontAwesomeIcons.fileAudio'
    $content = $content -replace '\bIcons\.call_outlined\b', 'FontAwesomeIcons.phone'
    $content = $content -replace '\bIcons\.cancel_outlined\b', 'FontAwesomeIcons.circleXmark'
    $content = $content -replace '\bIcons\.cast_connected_outlined\b', 'FontAwesomeIcons.wifi'
    $content = $content -replace '\bIcons\.chat_bubble_outline\b', 'FontAwesomeIcons.comment'
    $content = $content -replace '\bIcons\.check_circle_rounded\b', 'FontAwesomeIcons.solidCircleCheck'
    $content = $content -replace '\bIcons\.chevron_right\b', 'FontAwesomeIcons.chevronRight'
    $content = $content -replace '\bIcons\.circle_outlined\b', 'FontAwesomeIcons.circle'
    $content = $content -replace '\bIcons\.cleaning_services_outlined\b', 'FontAwesomeIcons.broom'
    $content = $content -replace '\bIcons\.description_outlined\b', 'FontAwesomeIcons.fileLines'
    $content = $content -replace '\bIcons\.edit\b', 'FontAwesomeIcons.penToSquare'
    $content = $content -replace '\bIcons\.error_outline\b', 'FontAwesomeIcons.circleExclamation'
    $content = $content -replace '\bIcons\.file_download_outlined\b', 'FontAwesomeIcons.download'
    $content = $content -replace '\bIcons\.gps_fixed_outlined\b', 'FontAwesomeIcons.crosshairs'
    $content = $content -replace '\bIcons\.group_work_outlined\b', 'FontAwesomeIcons.objectGroup'
    $content = $content -replace '\bIcons\.key_outlined\b', 'FontAwesomeIcons.key'
    $content = $content -replace '\bIcons\.keyboard_arrow_left_outlined\b', 'FontAwesomeIcons.chevronLeft'
    $content = $content -replace '\bIcons\.keyboard_arrow_right\b', 'FontAwesomeIcons.chevronRight'
    $content = $content -replace '\bIcons\.label\b', 'FontAwesomeIcons.tag'
    $content = $content -replace '\bIcons\.location_pin\b', 'FontAwesomeIcons.locationDot'
    $content = $content -replace '\bIcons\.mark_as_unread_outlined\b', 'FontAwesomeIcons.envelopeOpen'
    $content = $content -replace '\bIcons\.mark_as_unread\b', 'FontAwesomeIcons.envelopeOpen'
    $content = $content -replace '\bIcons\.menu\b', 'FontAwesomeIcons.bars'
    $content = $content -replace '\bIcons\.message_outlined\b', 'FontAwesomeIcons.comment'
    $content = $content -replace '\bIcons\.message\b', 'FontAwesomeIcons.solidComment'
    $content = $content -replace '\bIcons\.mic_none_outlined\b', 'FontAwesomeIcons.microphone'
    $content = $content -replace '\bIcons\.notifications_off\b', 'FontAwesomeIcons.bellSlash'
    $content = $content -replace '\bIcons\.pause_circle_outline_outlined\b', 'FontAwesomeIcons.circlePause'
    $content = $content -replace '\bIcons\.pause_outlined\b', 'FontAwesomeIcons.pause'
    $content = $content -replace '\bIcons\.phone_outlined\b', 'FontAwesomeIcons.phone'
    $content = $content -replace '\bIcons\.play_arrow_outlined\b', 'FontAwesomeIcons.play'
    $content = $content -replace '\bIcons\.play_circle_outline_outlined\b', 'FontAwesomeIcons.circlePlay'
    $content = $content -replace '\bIcons\.qr_code_rounded\b', 'FontAwesomeIcons.qrcode'
    $content = $content -replace '\bIcons\.star\b', 'FontAwesomeIcons.solidStar'
    $content = $content -replace '\bIcons\.tune_outlined\b', 'FontAwesomeIcons.sliders'
    $content = $content -replace '\bIcons\.upgrade_outlined\b', 'FontAwesomeIcons.arrowUp'
    $content = $content -replace '\bIcons\.video_call_outlined\b', 'FontAwesomeIcons.video'
    $content = $content -replace '\bIcons\.video_camera_back_outlined\b', 'FontAwesomeIcons.video'
    $content = $content -replace '\bIcons\.video_file_outlined\b', 'FontAwesomeIcons.fileVideo'
    $content = $content -replace '\bIcons\.videocam_outlined\b', 'FontAwesomeIcons.video'

    if ($content -ne $originalContent) {
        if ($content -notmatch 'font_awesome_flutter') {
            $content = $content -replace "(import 'package:flutter/material\.dart';)", "`$1`nimport 'package:font_awesome_flutter/font_awesome_flutter.dart';"
        }
        [System.IO.File]::WriteAllText($file.FullName, $content)
        Write-Host "Updated: $($file.FullName)"
    }
}

Write-Host "`nDone! Checking for remaining Icons. references..."
$remaining = Get-ChildItem -Path $libDir -Recurse -Filter "*.dart" | Select-String -Pattern '\bIcons\.\w+' -AllMatches | ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
Write-Host "Remaining unique icons: $($remaining.Count)"
foreach ($r in $remaining) {
    Write-Host "  $r"
}
