

if [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
    install_package libvirt-daemon
    sudo iniset /etc/libvirt/libvirtd.conf unix_sock_group stack
    sudo service libvirtd restart

elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
    # Restart after updating underlying numpy module
    sudo systemctl restart vcmmd

    # Neutron configuration
    # Containers need metadata service
    iniset $Q_DHCP_CONF_FILE DEFAULT force_metadata True

    # Tempest configuration
    # build a flavor for parallels VMs
    available_flavors=$(nova flavor-list)
    if [[ ! ( $available_flavors =~ 'm1.parallels' ) ]]; then
        nova flavor-create m1.parallels 1111 512 1 1
        nova flavor-create m1.parallels2 1112 768 2 2
    fi

    iniset $TEMPEST_CONFIG scenario img_file "${DEFAULT_IMAGE_NAME}.hds"
    iniset $TEMPEST_CONFIG scenario img_dir "$FILES"
    iniset $TEMPEST_CONFIG scenario img_disk_format "ploop"
    iniset $TEMPEST_CONFIG scenario img_container_format "bare"
    iniset $TEMPEST_CONFIG scenario ssh_user "centos"
    iniset $TEMPEST_CONFIG scenario dhcp_client "dhclient"

    if [[ $DEFAULT_IMAGE_NAME = "centos65-x32-hvm" ]]; then
        iniset $TEMPEST_CONFIG input-scenario image_regex "^centos65.*$"
    elif [[ $DEFAULT_IMAGE_NAME = "centos7-exe" ]]; then
        iniset $TEMPEST_CONFIG input-scenario image_regex "^centos7.*$"
        iniset $TEMPEST_CONFIG scenario img_properties "vm_mode:exe"
    fi

    iniset $TEMPEST_CONFIG input-scenario flavor_regex "^m1.parallels$"
    iniset $TEMPEST_CONFIG input-scenario ssh_user_regex "[[\"^centos7.*$\", \"centos\"]]"
    #overwrite flavor in compute section
    iniset $TEMPEST_CONFIG compute flavor_ref 1111
    iniset $TEMPEST_CONFIG compute flavor_ref_alt 1112
    iniset $TEMPEST_CONFIG volume volume_size 3

    # Libvirt-Parallels Cloud Server
    if [ "$VIRT_DRIVER" = "libvirt" ] && [ "$LIBVIRT_TYPE" = "parallels" ]; then
        iniset $TEMPEST_CONFIG compute-feature-enabled live_migration False
        iniset $TEMPEST_CONFIG compute-feature-enabled resize True
        iniset $TEMPEST_CONFIG compute-feature-enabled suspend True
        iniset $TEMPEST_CONFIG compute-feature-enabled vnc_console True
        iniset $TEMPEST_CONFIG compute-feature-enabled shelve False
        iniset $TEMPEST_CONFIG compute-feature-enabled console_output False
        iniset $TEMPEST_CONFIG compute-feature-enabled rescue True
        iniset $TEMPEST_CONFIG compute-feature-enabled interface_attach False
        iniset $TEMPEST_CONFIG compute-feature-enabled rebuild False
        iniset $TEMPEST_CONFIG compute-feature-enabled config_drive False
        iniset $TEMPEST_CONFIG compute volume_device_name sdb
    fi
fi
