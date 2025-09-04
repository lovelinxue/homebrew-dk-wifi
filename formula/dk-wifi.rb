class DkWifi < Formula
  desc "Auto-configure network when Wi-Fi is Daikin_Staff; revert to DHCP otherwise"
  homepage "https://github.com/lovelinxue/dk-wifi"
  url "https://github.com/lovelinxue/dk-wifi/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "fc76fe4783864f442f302436d43c8ae58494c89cbbf5ec7d9176088faf10638a"
  version "1.0.1"

  def install
    libexec.install "scripts/monitor_wifi.sh", "scripts/wifi_event_listener.sh"

    (bin/"dk-wifi-monitor").write <<~EOS
      #!/bin/bash
      exec "#{opt_libexec}/monitor_wifi.sh" "$@"
    EOS
    (bin/"dk-wifi-listen").write <<~EOS
      #!/bin/bash
      exec "#{opt_libexec}/wifi_event_listener.sh" "$@"
    EOS
    chmod 0755, bin/"dk-wifi-monitor"
    chmod 0755, bin/"dk-wifi-listen"
  end

  service do
    run ["/bin/bash", "-lc", "exec \"#{opt_libexec}/wifi_event_listener.sh\""]
    keep_alive true
    log_path var/"log/dk-wifi.log"
    error_log_path var/"log/dk-wifi.err.log"
  end

  def caveats
    <<~EOS
      1) 先执行一次初始化，输入你的内网 IP（不是192开头）：
         dk-wifi-monitor

      2) 启动常驻监听（开机自启）：
         brew services start lovelinxue/dk-wifi/dk-wifi

      3) 查看日志：
         tail -f ~/Library/NetworkScripts/monitor_wifi.log
    EOS
  end
end
