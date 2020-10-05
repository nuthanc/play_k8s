### test_kube_dns_lookup

* Path in tf-test: scripts/k8s_scripts/test_service.py
* DNS doc link: https://medium.com/kubernetes-tutorials/kubernetes-dns-for-services-and-pods-664804211501
  * kubelet passes DNS functionality to each container with the --cluster-dns=<dns-service-ip> flag
* Uses nslookup for dns related info
TODO INCOMPLETE, check for this testcase again