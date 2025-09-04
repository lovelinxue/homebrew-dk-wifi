class DkWifi < Formula
  desc "Auto-configure network when connected to Daikin_Staff; revert to DHCP otherwise"
  homepage "https://github.com/lovelinxue/dk-wifi"
  url "https://github.com/lovelinxue/dk-wifi/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "daea4de8741902c20a97722f6c4c90f3572450b012195463006692ebd0d21354"
  version "1.0.0"

  def install
    libexec.install Dir["scripts/*"]

    # 提供命令入口
    (bin/"dk-wifi-monitor").write <<~EOS
      #!/bin/bash
      exec "$HOME/Library/NetworkScripts/monitor_wifi.sh" "$@"
    EOS
    (bin/"dk-wifi-listen").write <<~EOS
      #!/bin/bash
      exec "$HOME/Library/NetworkScripts/wifi_event_listener.sh" "$@"
    EOS
    chmod 0755, bin/"dk-wifi-monitor"
    chmod 0755, bin/"dk-wifi-listen"
  end

  def post_install
    require "fileutils"
    netscripts = File.join(Dir.home, "Library/NetworkScripts")
    launch_agents = File.join(Dir.home, "Library/LaunchAgents")

    FileUtils.mkdir_p netscripts
    FileUtils.mkdir_p launch_agents

    # 把脚本复制到用户目录
    Dir["#{libexec}/*"].each do |src|
      FileUtils.cp src, netscripts
    end
    Dir["#{netscripts}/*.sh"].each do |sh|
      FileUtils.chmod 0755, sh
    end

    # 写 plist
    plist_path = File.join(launch_agents, "com.dk.event.listener.plist")
    plist_content = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.dk.event.listener</string>
        <key>ProgramArguments</key>
        <array>
          <string>/bin/bash</string>
          <string>-lc</string>
          <string>exec "$HOME/Library/NetworkScripts/wifi_event_listener.sh"</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
      </dict>
      </plist>
    PLIST
    File.write(plist_path, plist_content)

    # 加载监听（若已存在旧的，先卸载再加载）
    system "launchctl", "unload", plist_path rescue nil
    system "launchctl", "load", plist_path
  end

  def caveats
    <<~EOS
      ✅ dk-wifi 已安装，并注册开机自启监听。

      👉 首次使用，请手动运行一次初始化，输入你的内网 IP（不是192开头的）：
         dk-wifi-monitor

      👉 查看日志：
         tail -f ~/Library/NetworkScripts/monitor_wifi.log
    EOS
  end
end
