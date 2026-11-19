# Azul Optimizer Hub Helm Charts

Optimizer Hub is a component of Azul Platform Prime that makes your Java programs start fast and stay fast. It consists of two services:

* **Cloud Native Compiler**: Provides a server-side optimization solution that offloads JIT compilation from Zing’s Falcon JIT compiler to separate and dedicated service resources, providing more processing power to JIT compilation while freeing your client JVMs from the burden of doing JIT compilation locally.
* **ReadyNow Orchestrator**: Records and serves ReadyNow profiles. This greatly simplifies the operational use of the ReadyNow, and removes the need to configure any local storage for writing the profile. ReadyNow Orchestrator can record multiple profile candidates from multiple JVMs and promote the best recorded profile.

## Installing on Kubernetes

Optimizer Hub is shipped as a Kubernetes cluster which you provision and run on your cloud or on-premise servers. You can install Optimizer Hub on any Kubernetes cluster:

* **Kubernetes** clusters that you manually configure with `kubeadm`.
* **Managed cloud Kubernetes** services such as Amazon Web Services Elastic Kubernetes Service (EKS), Google Kubernetes Engine, and Microsoft Azure Managed Kubernetes Service.
* A single-node **minikube** cluster, only for evaluation purposes. 
 
The full installation instructions are available [on the Azul documentation website](https://docs.azul.com/optimizer-hub/installation/install-optimizer-hub).

## More Information

* [Azul Platform Prime](https://www.azul.com/products/prime/)
* [Optimizer Hub product page](https://www.azul.com/products/components/azul-optimizer-hub/)
* [Optimizer Hub documentation](https://docs.azul.com/optimizer-hub/) 

## Licensing

The Helm Charts, templates, and configuration files in this repository are licensed under the MIT License (see [License.txt](License.txt)). The MIT License does not apply to Optimizer Hub, Cloud Native Compiler, or any other software or container images these Helm Charts deploy. Third-party charts pulled in as dependencies (Prometheus, Grafana) are subject to their own licenses.
