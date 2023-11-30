# Update AKS node pool SKU

The AKS service of Cosmo Tech Platform contains a set of node pools sized in order to cover most of the use cases. However some cases can require an increase of the VM size of the nodes, as:
* `services` nodes are too small in memory and API start is unstable. `services` default VM size `Standard_A2m_v2` should be upgraded to `Standard_B4ms`.
* `basic` nodes are too small in memory for dataset import. `basic` default VM size `Standard_D2ads_v5` should be upgraded to `Standard_F4s_v2`
* `highmemory` nodes are too large and can be reduced for lower Azure consumption. `highmemory` default VM size `Standard_E16ads_v5` should be downgraded to `Standard_E8ads_v5`

This procedure enables to update an AKS node pool SKU with no availability interruption. 

Microsoft documentation is available for this type of operation: https://learn.microsoft.com/en-us/azure/aks/resize-node-pool?tabs=azure-cli

## Prerequisites

* Be Contributor over the AKS
* Be Network Contributor over Virtual Network
* Use k9s or equivalent in order to monitor AKS cluster
* Kubernetes version of the AKS should be supported by Azure. If the AKS version is deprecated:
```bash
# get the available versions for upgrade
az aks get-upgrades --resource-group "<resource_group>" --name "<AKS_cluster_name>" --output table
# upgrade kubernetes version
az aks upgrade --resource-group "<resource_group>" --name "<AKS_cluster_name>" --kubernetes-version "<target_version>"
```

## Resizing steps

It is not possible to update the VM size of a node. The procedure requires to create a new node pool, and delete the old one afterwards.

**Create new node pool**

```bash
# command for creation of new "basic" node pool
az aks nodepool add --cluster-name "<AKS_cluster_name>" \
                    -g "<resource_group>" \
                    --name "new_nodepool_name" \
                    --node-count 2 \
                    --node-vm-size "Standard_F4s_v2" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 5 \
                    --min-count 1 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=compute" "cosmotech.com/size=basic" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

# command for creation of new "services" node pool
az aks nodepool add --cluster-name "<AKS_cluster_name>" \
                    -g "<resource_group>" \
                    --name "new_nodepool_name" \
                    --node-count 2 \
                    --node-vm-size "Standard_B4ms" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 5 \
                    --min-count 2 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=services" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

# command for creation of new "highmemory" node pool
az aks nodepool add --cluster-name "<AKS_cluster_name>" \
                    -g "<resource_group>" \
                    --name "new_nodepool_name" \
                    --node-count 0 \
                    --node-vm-size "Standard_E8ads_v5" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 3 \
                    --min-count 0 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=compute" "cosmotech.com/size=highmemory" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

```

**Cordon and drain the nodes**

List all the nodes of the cluster, in order to identify which nodes to cordon and drain.
```bash
# Connect to AKS context
kubectl get nodes
```

Cordon each node of the pool you want to remove in order to prevent new pods to get deployed on it.
```bash
# Connect to AKS context
kubectl cordon "<node_name>"
```

Drain each node of the pool you want to remove in order to remove all pods running.
```bash
# Connect to AKS context
kubectl drain "<node_name>" --ignore-daemonsets --delete-emptydir-data
```

**Delete node pool**

Delete the old node pool.
```bash
az aks nodepool delete \
    --resource-group "<resource_group>" \
    --cluster-name "<AKS_cluster_name>" \
    --name "nodepool_name"
```
