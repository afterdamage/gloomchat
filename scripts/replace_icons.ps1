# PowerShell script to replace Material Icons with Font Awesome icons
# and add the font_awesome_flutter import to files that need it

$libDir = "c:\gloomchat\lib"

# Get all Dart files with Icons. references
$files = Get-ChildItem -Path $libDir -Recurse -Filter "*.dart" | 
    Where-Object { (Get-Content $_.FullName -Raw) -match '\bIcons\.' -or (Get-Content $_.FullName -Raw) -match '\bCupertinoIcons\.' }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Icon replacements - Map Material Icons to Font Awesome
    # Navigation / General
    $content = $content -replace '\bIcons\.home_outlined\b', 'FontAwesomeIcons.house'
    $content = $content -replace '\bIcons\.home\b', 'FontAwesomeIcons.house'
    $content = $content -replace '\bIcons\.settings_outlined\b', 'FontAwesomeIcons.gear'
    $content = $content -replace '\bIcons\.settings\b', 'FontAwesomeIcons.solidGear'
    $content = $content -replace '\bIcons\.search_outlined\b', 'FontAwesomeIcons.magnifyingGlass'
    $content = $content -replace '\bIcons\.search\b', 'FontAwesomeIcons.magnifyingGlass'
    $content = $content -replace '\bIcons\.add_outlined\b', 'FontAwesomeIcons.plus'
    $content = $content -replace '\bIcons\.add_a_photo_outlined\b', 'FontAwesomeIcons.cameraRetro'
    $content = $content -replace '\bIcons\.add\b', 'FontAwesomeIcons.plus'
    $content = $content -replace '\bIcons\.close_outlined\b', 'FontAwesomeIcons.xmark'
    $content = $content -replace '\bIcons\.close\b', 'FontAwesomeIcons.xmark'
    $content = $content -replace '\bIcons\.clear_outlined\b', 'FontAwesomeIcons.xmark'
    
    # Edit / Actions
    $content = $content -replace '\bIcons\.edit_outlined\b', 'FontAwesomeIcons.penToSquare'
    $content = $content -replace '\bIcons\.delete_forever_outlined\b', 'FontAwesomeIcons.trash'
    $content = $content -replace '\bIcons\.delete_sweep_outlined\b', 'FontAwesomeIcons.trash'
    $content = $content -replace '\bIcons\.delete_outline\b', 'FontAwesomeIcons.trash'
    $content = $content -replace '\bIcons\.delete_outlined\b', 'FontAwesomeIcons.trash'
    $content = $content -replace '\bIcons\.delete\b', 'FontAwesomeIcons.trash'
    $content = $content -replace '\bIcons\.copy_outlined\b', 'FontAwesomeIcons.copy'
    $content = $content -replace '\bIcons\.copy\b', 'FontAwesomeIcons.copy'
    $content = $content -replace '\bIcons\.download_outlined\b', 'FontAwesomeIcons.download'
    $content = $content -replace '\bIcons\.upload_outlined\b', 'FontAwesomeIcons.upload'
    $content = $content -replace '\bIcons\.refresh_outlined\b', 'FontAwesomeIcons.arrowsRotate'
    $content = $content -replace '\bIcons\.reply_outlined\b', 'FontAwesomeIcons.reply'
    
    # Share
    $content = $content -replace '\bIcons\.adaptive\.share_outlined\b', 'FontAwesomeIcons.shareNodes'
    $content = $content -replace '\bIcons\.share_outlined\b', 'FontAwesomeIcons.shareNodes'
    
    # Notifications
    $content = $content -replace '\bIcons\.notifications_off_outlined\b', 'FontAwesomeIcons.bellSlash'
    $content = $content -replace '\bIcons\.notifications_on_outlined\b', 'FontAwesomeIcons.bell'
    $content = $content -replace '\bIcons\.notifications_outlined\b', 'FontAwesomeIcons.bell'
    
    # Info / Status
    $content = $content -replace '\bIcons\.info_outline_rounded\b', 'FontAwesomeIcons.circleInfo'
    $content = $content -replace '\bIcons\.info_outlined\b', 'FontAwesomeIcons.circleInfo'
    $content = $content -replace '\bIcons\.error_outline_outlined\b', 'FontAwesomeIcons.circleExclamation'
    $content = $content -replace '\bIcons\.error_outlined\b', 'FontAwesomeIcons.circleExclamation'
    $content = $content -replace '\bIcons\.error\b', 'FontAwesomeIcons.circleExclamation'
    $content = $content -replace '\bIcons\.warning_outlined\b', 'FontAwesomeIcons.triangleExclamation'
    $content = $content -replace '\bIcons\.warning\b', 'FontAwesomeIcons.triangleExclamation'
    $content = $content -replace '\bIcons\.check_circle\b', 'FontAwesomeIcons.solidCircleCheck'
    $content = $content -replace '\bIcons\.check_outlined\b', 'FontAwesomeIcons.check'
    $content = $content -replace '\bIcons\.check\b', 'FontAwesomeIcons.check'
    $content = $content -replace '\bIcons\.verified_outlined\b', 'FontAwesomeIcons.shieldHalved'
    
    # People / Users
    $content = $content -replace '\bIcons\.person_2\b', 'FontAwesomeIcons.user'
    $content = $content -replace '\bIcons\.person_add_outlined\b', 'FontAwesomeIcons.userPlus'
    $content = $content -replace '\bIcons\.person_remove_outlined\b', 'FontAwesomeIcons.userMinus'
    $content = $content -replace '\bIcons\.account_circle_outlined\b', 'FontAwesomeIcons.circleUser'
    $content = $content -replace '\bIcons\.account_box_outlined\b', 'FontAwesomeIcons.circleUser'
    $content = $content -replace '\bIcons\.how_to_reg_outlined\b', 'FontAwesomeIcons.userCheck'
    $content = $content -replace '\bIcons\.admin_panel_settings_outlined\b', 'FontAwesomeIcons.userShield'
    $content = $content -replace '\bIcons\.group_add_outlined\b', 'FontAwesomeIcons.userGroup'
    $content = $content -replace '\bIcons\.group_outlined\b', 'FontAwesomeIcons.users'
    $content = $content -replace '\bIcons\.group_remove_outlined\b', 'FontAwesomeIcons.userXmark'
    $content = $content -replace '\bIcons\.alternate_email_outlined\b', 'FontAwesomeIcons.at'
    $content = $content -replace '\bIcons\.people_outlined\b', 'FontAwesomeIcons.users'
    
    # Chat / Forum
    $content = $content -replace '\bIcons\.forum_outlined\b', 'FontAwesomeIcons.comments'
    $content = $content -replace '\bIcons\.forum\b', 'FontAwesomeIcons.solidComments'
    $content = $content -replace '\bCupertinoIcons\.chat_bubble_text_fill\b', 'FontAwesomeIcons.solidComment'
    
    # Security / Lock
    $content = $content -replace '\bIcons\.lock_open_outlined\b', 'FontAwesomeIcons.lockOpen'
    $content = $content -replace '\bIcons\.lock_outlined\b', 'FontAwesomeIcons.lock'
    $content = $content -replace '\bIcons\.lock\b', 'FontAwesomeIcons.lock'
    $content = $content -replace '\bIcons\.block_outlined\b', 'FontAwesomeIcons.ban'
    $content = $content -replace '\bIcons\.block\b', 'FontAwesomeIcons.ban'
    $content = $content -replace '\bIcons\.shield_outlined\b', 'FontAwesomeIcons.shield'
    $content = $content -replace '\bIcons\.vpn_key_outlined\b', 'FontAwesomeIcons.key'
    $content = $content -replace '\bIcons\.password_outlined\b', 'FontAwesomeIcons.key'
    $content = $content -replace '\bIcons\.gavel_outlined\b', 'FontAwesomeIcons.gavel'
    
    # Media
    $content = $content -replace '\bIcons\.camera_alt_outlined\b', 'FontAwesomeIcons.camera'
    $content = $content -replace '\bIcons\.photo_outlined\b', 'FontAwesomeIcons.image'
    $content = $content -replace '\bIcons\.broken_image_outlined\b', 'FontAwesomeIcons.image'
    $content = $content -replace '\bIcons\.image_outlined\b', 'FontAwesomeIcons.image'
    $content = $content -replace '\bIcons\.emoji_emotions_outlined\b', 'FontAwesomeIcons.faceSmile'
    $content = $content -replace '\bIcons\.zoom_in_outlined\b', 'FontAwesomeIcons.magnifyingGlassPlus'
    $content = $content -replace '\bIcons\.zoom_out_outlined\b', 'FontAwesomeIcons.magnifyingGlassMinus'
    $content = $content -replace '\bIcons\.file_present_outlined\b', 'FontAwesomeIcons.file'
    
    # Devices
    $content = $content -replace '\bIcons\.phone_android_outlined\b', 'FontAwesomeIcons.mobileScreen'
    $content = $content -replace '\bIcons\.phone_iphone_outlined\b', 'FontAwesomeIcons.mobile'
    $content = $content -replace '\bIcons\.web_outlined\b', 'FontAwesomeIcons.globe'
    $content = $content -replace '\bIcons\.desktop_mac_outlined\b', 'FontAwesomeIcons.desktop'
    $content = $content -replace '\bIcons\.desktop_mac\b', 'FontAwesomeIcons.desktop'
    $content = $content -replace '\bIcons\.device_unknown_outlined\b', 'FontAwesomeIcons.question'
    $content = $content -replace '\bIcons\.devices_outlined\b', 'FontAwesomeIcons.laptop'
    
    # Misc
    $content = $content -replace '\bIcons\.favorite\b', 'FontAwesomeIcons.solidHeart'
    $content = $content -replace '\bIcons\.source_outlined\b', 'FontAwesomeIcons.code'
    $content = $content -replace '\bIcons\.list_outlined\b', 'FontAwesomeIcons.list'
    $content = $content -replace '\bIcons\.settings_applications_outlined\b', 'FontAwesomeIcons.gears'
    $content = $content -replace '\bIcons\.format_paint_outlined\b', 'FontAwesomeIcons.paintbrush'
    $content = $content -replace '\bIcons\.archive_outlined\b', 'FontAwesomeIcons.boxArchive'
    $content = $content -replace '\bIcons\.privacy_tip_outlined\b', 'FontAwesomeIcons.userShield'
    $content = $content -replace '\bIcons\.logout_outlined\b', 'FontAwesomeIcons.rightFromBracket'
    $content = $content -replace '\bIcons\.link_outlined\b', 'FontAwesomeIcons.link'
    $content = $content -replace '\bIcons\.open_in_new_outlined\b', 'FontAwesomeIcons.arrowUpRightFromSquare'
    $content = $content -replace '\bIcons\.backup_outlined\b', 'FontAwesomeIcons.cloudArrowUp'
    $content = $content -replace '\bIcons\.dns_outlined\b', 'FontAwesomeIcons.server'
    $content = $content -replace '\bIcons\.explore_outlined\b', 'FontAwesomeIcons.compass'
    $content = $content -replace '\bIcons\.workspaces_outlined\b', 'FontAwesomeIcons.cubes'
    
    # Arrows / Navigation
    $content = $content -replace '\bIcons\.arrow_downward_outlined\b', 'FontAwesomeIcons.arrowDown'
    $content = $content -replace '\bIcons\.arrow_upward_outlined\b', 'FontAwesomeIcons.arrowUp'
    $content = $content -replace '\bIcons\.arrow_back\b', 'FontAwesomeIcons.arrowLeft'
    $content = $content -replace '\bIcons\.arrow_drop_down_circle_outlined\b', 'FontAwesomeIcons.circleChevronDown'
    $content = $content -replace '\bIcons\.chevron_right_outlined\b', 'FontAwesomeIcons.chevronRight'
    $content = $content -replace '\bIcons\.move_down_outlined\b', 'FontAwesomeIcons.arrowDown'
    
    # Theme / Display
    $content = $content -replace '\bIcons\.light_mode_outlined\b', 'FontAwesomeIcons.sun'
    $content = $content -replace '\bIcons\.dark_mode_outlined\b', 'FontAwesomeIcons.moon'
    $content = $content -replace '\bIcons\.auto_mode_outlined\b', 'FontAwesomeIcons.circleHalfStroke'
    $content = $content -replace '\bIcons\.color_lens_outlined\b', 'FontAwesomeIcons.palette'
    
    # Phone / Call
    $content = $content -replace '\bIcons\.call_end\b', 'FontAwesomeIcons.phoneSlash'
    $content = $content -replace '\bIcons\.phone\b', 'FontAwesomeIcons.phone'
    $content = $content -replace '\bIcons\.mic_off\b', 'FontAwesomeIcons.microphoneSlash'
    $content = $content -replace '\bIcons\.mic\b', 'FontAwesomeIcons.microphone'
    $content = $content -replace '\bIcons\.volume_up\b', 'FontAwesomeIcons.volumeHigh'
    $content = $content -replace '\bIcons\.volume_off\b', 'FontAwesomeIcons.volumeXmark'
    $content = $content -replace '\bIcons\.switch_camera\b', 'FontAwesomeIcons.cameraRotate'
    $content = $content -replace '\bIcons\.pause\b', 'FontAwesomeIcons.pause'
    $content = $content -replace '\bIcons\.videocam_off\b', 'FontAwesomeIcons.videoSlash'
    $content = $content -replace '\bIcons\.videocam\b', 'FontAwesomeIcons.video'
    
    # Chat Input
    $content = $content -replace '\bIcons\.send_outlined\b', 'FontAwesomeIcons.paperPlane'
    $content = $content -replace '\bIcons\.send\b', 'FontAwesomeIcons.solidPaperPlane'
    $content = $content -replace '\bIcons\.attach_file_outlined\b', 'FontAwesomeIcons.paperclip'
    $content = $content -replace '\bIcons\.attach_file\b', 'FontAwesomeIcons.paperclip'
    $content = $content -replace '\bIcons\.keyboard\b', 'FontAwesomeIcons.keyboard'
    $content = $content -replace '\bIcons\.location_on_outlined\b', 'FontAwesomeIcons.locationDot'
    $content = $content -replace '\bIcons\.location_on\b', 'FontAwesomeIcons.locationDot'
    $content = $content -replace '\bIcons\.gif_box_outlined\b', 'FontAwesomeIcons.film'
    $content = $content -replace '\bIcons\.text_fields_outlined\b', 'FontAwesomeIcons.font'
    $content = $content -replace '\bIcons\.record_voice_over_outlined\b', 'FontAwesomeIcons.microphone'
    
    # More misc
    $content = $content -replace '\bIcons\.cancel\b', 'FontAwesomeIcons.circleXmark'
    $content = $content -replace '\bIcons\.import_export_outlined\b', 'FontAwesomeIcons.arrowRightArrowLeft'
    $content = $content -replace '\bIcons\.repeat_outlined\b', 'FontAwesomeIcons.repeat'
    $content = $content -replace '\bIcons\.lock_reset_outlined\b', 'FontAwesomeIcons.key'
    $content = $content -replace '\bIcons\.remove_circle\b', 'FontAwesomeIcons.circleXmark'
    $content = $content -replace '\bIcons\.qr_code_scanner_outlined\b', 'FontAwesomeIcons.qrcode'
    $content = $content -replace '\bIcons\.public_outlined\b', 'FontAwesomeIcons.globe'
    $content = $content -replace '\bIcons\.visibility_off_outlined\b', 'FontAwesomeIcons.eyeSlash'
    $content = $content -replace '\bIcons\.visibility_outlined\b', 'FontAwesomeIcons.eye'
    $content = $content -replace '\bIcons\.mail_outline_rounded\b', 'FontAwesomeIcons.envelope'
    $content = $content -replace '\bIcons\.pin_drop_outlined\b', 'FontAwesomeIcons.thumbtack'
    $content = $content -replace '\bIcons\.push_pin_outlined\b', 'FontAwesomeIcons.thumbtack'
    $content = $content -replace '\bIcons\.push_pin\b', 'FontAwesomeIcons.thumbtack'
    
    # Remaining catch-alls
    $content = $content -replace '\bIcons\.more_vert\b', 'FontAwesomeIcons.ellipsisVertical'
    $content = $content -replace '\bIcons\.more_horiz\b', 'FontAwesomeIcons.ellipsis'
    $content = $content -replace '\bIcons\.navigate_next\b', 'FontAwesomeIcons.chevronRight'
    $content = $content -replace '\bIcons\.navigate_before\b', 'FontAwesomeIcons.chevronLeft'
    $content = $content -replace '\bIcons\.play_arrow\b', 'FontAwesomeIcons.play'
    $content = $content -replace '\bIcons\.stop\b', 'FontAwesomeIcons.stop'
    $content = $content -replace '\bIcons\.map_outlined\b', 'FontAwesomeIcons.map'
    $content = $content -replace '\bIcons\.poll_outlined\b', 'FontAwesomeIcons.squarePollVertical'
    $content = $content -replace '\bIcons\.shortcut_outlined\b', 'FontAwesomeIcons.shareFromSquare'
    
    # Encryption related
    $content = $content -replace '\bIcons\.enhanced_encryption_outlined\b', 'FontAwesomeIcons.lock'
    $content = $content -replace '\bIcons\.no_encryption_outlined\b', 'FontAwesomeIcons.lockOpen'
    $content = $content -replace '\bIcons\.encrypt_outlined\b', 'FontAwesomeIcons.lock'

    # Only write if changed
    if ($content -ne $originalContent) {
        # Add import if not already present
        if ($content -notmatch 'font_awesome_flutter') {
            $content = $content -replace "(import 'package:flutter/material\.dart';)", "`$1`nimport 'package:font_awesome_flutter/font_awesome_flutter.dart';"
        }
        
        [System.IO.File]::WriteAllText($file.FullName, $content)
        Write-Host "Updated: $($file.FullName)"
    }
}

Write-Host "`nDone! Checking for remaining Icons. references..."
$remaining = Get-ChildItem -Path $libDir -Recurse -Filter "*.dart" | Select-String -Pattern '\bIcons\.' | Select-Object -Property Path -Unique
Write-Host "Files still with Icons.: $($remaining.Count)"
foreach ($r in $remaining) {
    Write-Host "  $($r.Path)"
}
