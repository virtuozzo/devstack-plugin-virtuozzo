

if [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
    virtuozzo_ct_pre_install_checks

elif [[ "$1" == "stack" && "$2" == "install" ]]; then
    virtuozzo_adjust_libvirtd_conf
    # Restart after updating underlying numpy module
    sudo service vcmmd restart

elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
    virtuozzo_ct_post_config_neutron
    virtuozzo_adjust_nova_conf

elif [[ "$1" == "stack" && "$2" = "test-config" ]]; then
    if is_service_enabled tempest; then 
         virtuozzo_ct_tempest_conf
    fi
fi
