# Release Notes

## 0.7.0 beta (Aug, 2022)

Initial release of loxilb     

- **Functional Features**:    
    - Two-Arm Load-Balancer (NAT+Routed mode)     
        - Upto 16 end-points support    
    - Load-balancer selection policy    
        -  Round-robin, traffic-hash (fallback to RR if hash fails)    
    - Conntrack support in eBPF - TCP/UDP/ICMP/SCTP profiles    
    - GTP with QFI extension support    
        - ULCL classifier support    
    - Native QoS-Policer support (SRTCM/TRTCM)    
    - GoBGP Integration          
    - Extended visibility and statistics     

- **LB Spec Support**:     
    - IP allocation policy    
    - Kubernetes 1.20 base support
    - Support for Calico CNI  
 
- **Utilities**:     
    - loxicmd support : Configuration utlity with the look and feel of kubectl    

## 0.8.0 (Dec, 2022) - Planned      

- **Functional Features**:    
    - Enhanced load-balancer support including SCTP statefulness, WRR distribution    
    - Integrated Firewall support    
    - Integrated end-point health-checks    
    - One-ARM, FullNAT, DSR LB mode support    
    - NAT66/NAT64 support    
    - Clustering support      
    - Integration with Linux egress TC hooks    
  
- **LB Spec**:    
    - Stand-alone mode to support LB Spec [kube-loxilb](https://github.com/loxilb-io/kube-loxilb)    
    - Load-balancer class support    
    - Advanced IPAM for ipv4/ipv6 with shared/exclusive mode    
    - Kubernetes 1.25 Integration     

- **Utilities**:  
    - loxicmd support : Data-Store support, more commands

## 0.9.0 (Nov, 2023) - Planned   

- **Functional Features**:  
    - Hardened NAT Support - CGNAT'ish   
    - L3 DSR mode Support   
    - Https end-point liveness probes   
    - Maglev clustering  
    - Transition to libbpf v1.0.1   
    - SCTP multihoming support   
    - Integration with Linux native QoS   
    - Support for Cilium, Weave CNI   
    - Grafana based dashboard   

- **kube-loxilb/LB Spec Support**: 
    - OpenShift Integration    
    - Support for per-service liveness-checks, IPAM type, multi-homing annotations   
    - Kubernetes 1.26 (k0s, k3s, k8s )   
    - Operator support   
    - AWS EKS support   

## 0.9.5 (Jan, 2024) - Planned   

- **Functional Features**:
    - SRv6 support  
    - Rolling upgrades   
    - L7 proxy   
    - URL Filtering       
    - DNS caching   
    - IPSEC/Wireguard support    

- **kube-loxilb Support**: 
    - Kubernetes 1.27    
    - BGP Mesh support    
    - Multi-cluster support   
    - ULCL filter integration       
