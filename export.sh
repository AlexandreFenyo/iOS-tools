#!/bin/zsh

ssh v rm -rf public_html/wifimapexplorer/export
ssh v mkdir public_html/wifimapexplorer/export
scp /Users/fenyo/export/iOS\ tools.ipa v:public_html/wifimapexplorer/export/foo.ipa
scp /Users/fenyo/export/manifest.plist v:public_html/wifimapexplorer/export
echo 'click <a href="itms-services://?action=download-manifest&url=https://fenyo.net/wifimapexplorer/export/manifest.plist">here</a>' > /Users/fenyo/export/download.html
scp /Users/fenyo/export/download.html v:public_html/wifimapexplorer/export
