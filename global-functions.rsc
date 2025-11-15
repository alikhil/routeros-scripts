### $SECRET
#   get <name>
#   set <name> password=<password>
# . remove <name
#   print
:global SECRET
:set $SECRET do={
    :global SECRET

    # helpers
    :local fixprofile do={
        :if ([/ppp profile find name="null"]) do={:put "nothing"} else={
            /ppp profile add bridge-learning=no change-tcp-mss=no local-address=0.0.0.0 name="null" only-one=yes remote-address=0.0.0.0 session-timeout=1s use-compression=no use-encryption=no use-mpls=no use-upnp=no
        }
    }
    :local lppp [:len [/ppp secret find where name=$2]]
    :local checkexist do={
        :if (lppp=0) do={
            :error "\$SECRET: cannot find $2 in secret store"
        }
    }

    # $SECRET
    :if ([:typeof $1]!="str") do={
        :put "\$SECRET"
        :put "   uses /ppp/secrets to store stuff like REST apikeys, or other sensative data"
        :put "\t\$SECRET print - prints stored secret passwords"
        :put "\t\$SECRET get <name> - gets a stored secret"
        :put "\t\$SECRET set <name> password=\"YOUR_SECRET\" - sets a secret password"
        :put "\t\$SECRET remove <name> - removes a secret"
    }

    # $SECRET print
    :if ($1~"^pr") do={
        /ppp secret print where comment~"\\\$SECRET"
        :return [:nothing]
    }

    # $SECRET get
    :if ($1~"get") do={
        $checkexist
       :return [/ppp secret get $2 password]
    }

    # $SECRET set
    :if ($1~"set|add") do={
        :if ([:typeof $password]="str") do={} else={:error "\$SECRET: password= required"}
        :if (lppp=0) do={
            /ppp secret add name=$2 password=$password
        } else={
            /ppp secret set $2 password=$password
        }
        $fixprofile
        /ppp secret set $2 comment="used by \$SECRET"
        /ppp secret set $2 profile="null"
        /ppp secret set $2 service="async"
        :return [$SECRET get $2]
    }

    # $SECRET remove
    :if ($1~"rm|rem|del") do={
        $checkexist
        :return [/ppp secret remove $2]
    }
    :error "\$SECRET: bad command"
}

:global sendTelegramMessage do={
    :global SECRET
    :local botToken
    :set botToken "$[$SECRET get TELEGRAM_TOKEN]"
    :local chatId "$[$SECRET get TELEGRAM_CHAT_ID]"
    :local message "$1"


    # telegram notification
    /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage\?chat_id=$chatId&text=$message" keep-result=no
}


# source https://forum.mikrotik.com/viewtopic.php?t=144577

# script to disable secondary DNS when adguard is back up
:global disableBackup do={
    # set variables
    :local adguardIP "192.168.11.2"
    :local message "\E2\9C\85 Primary DNS $adguardIP is up. Switching Cloudflare DNS to Adguard."
    :local myhost ([/system identity get name])

    :if ([/ip dns get servers]!=$adguardIP) do={

    :log info "BackupDNS: Adguard up, stopping"

    # change resolver back to adguard
    /ip dns set servers=$adguardIP
    :delay 1
    :log info "BackupDNS: adguard now set as resolver"

    # disable DNS server and flush the cache
    :delay 1
    /ip dns cache flush
    :log info "BackupDNS: DNS server disabled and cache flushed"

    :global sendTelegramMessage
    # telegram notification
    $sendTelegramMessage $message

    } else={ :log info "BackupDNS: Adguard is up but it's already in router's DNS, script exited" }
}

# script to enable backupDNS if adguard doesn't ping

:global enableBackup do={
    # set variables
    :local adguardIP "192.168.11.2"
    :local message "\E2\9D\8C Primary DNS $adguardIP is down. Switching to Cloudflare DNS from Adguard."
    :local myhost ([/system identity get name])

    :if ([/ip dns get servers]=$adguardIP) do={
        :log info "BackupDNS: adguard down, enabling"
        # change to your upstream resolvers
        /ip dns set servers=1.1.1.1,8.8.8.8
        :delay 2
        :log info "BackupDNS: resolvers changed"

        :delay 1
        /ip dns cache flush

        :global sendTelegramMessage

        # telegram notification
        $sendTelegramMessage $message

    } else={ :log info "BackupDNS: Router os already configured not to use Adguard, script exited" }

}

:global updateFunctions do={
    :put "Updating global functions..."
    :foreach Script in={ "global-functions" } do={ /system/script/set $Script source=([ /tool/fetch ("https://raw.githubusercontent.com/alikhil/routeros-scripts/main/" . $Script . ".rsc") output=user as-value]->"data"); };
}