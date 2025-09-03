# Azul Optimizer Hub Helm Charts

[Azul Optimizer Hub](https://www.azul.com/products/intelligence-cloud/cloud-native-compiler/) is a server-side optimization solution that offloads JIT compilation to separate and dedicated service resources, providing more processing power to JIT compilation while freeing your client JVMs from the burden of doing JIT compilation locally.

Optimizer Hub is shipped as a Kubernetes cluster which you provision and run on your cloud or on-premise servers. You can install Optimizer Hub on any Kubernetes cluster:

* Kubernetes clusters that you manually configure with kubeadm
* A single-node minikube cluster. You should run Optimizer Hub on minikube only for evaluation purposes. Make sure your minikube meets the 18vCore minimum for running Optimizer Hub.
* Managed cloud Kubernetes services such as Amazon Web Services Elastic Kubernetes Service (EKS), Google Kubernetes Engine, and Microsoft Azure Managed Kubernetes Service.

See the [Optimizer Hub Documentation](https://docs.azul.com/optimizer-hub/) for more information. *Note:* By downloading and using Optimizer Hub Installer you are agreeing to the [Optimizer Hub Evaluation Agreement](https://www.azul.com/wp-content/uploads/Azul-Platform-Prime-Evaluation-Agreement.pdf).

To install Optimizer Hub:

1. [Install Azul Zulu Prime](https://www.azul.com/downloads/) version 21.09.01 or later on your client machine.
2. Make sure your Helm version is v3.8.0 or later.
3. Add the Azul Helm repository to your Helm environment:
```bash
helm repo add opthub-helm https://azulsystems.github.io/opthub-helm-charts/
helm repo update
```
4. Create a namespace (i.e. `opthub`) for the Optimizer Hub service.
```bash
kubectl create namespace opthub
```
5. Create the `values-override.yaml` file in your local directory.
6. If you have a custom cluster domain name, you will need to provide it:
```yaml
clusterName: "example.org"
```
7. Configure sizing and autoscaling of the Optimizer Hub components according to the [sizing guide](https://docs.azul.com/optimizer-hub/configuring/sizing-and-scaling). By default autoscaling is on and the Optimizer Hub service can scale up to 10 Compile Brokers.
8. If needed, configure external access in your cluster. If your JVMs are running within the same cluster as Optimizer Hub, you can ignore this step. Otherwise, it is necessary to configure an external load balancer in `values-override.yaml`.
For clusters running on AWS an [example configuration file](https://github.com/AzulSystems/opthub-helm-charts/blob/master/values-awslb.yaml) is available in this GitHub project.

9. Install using Helm, passing in the `values-override.yaml`:
```bash
helm install opthub opthub-helm/azul-opthub -n opthub -f values-override.yaml
```
In case you need a specific Optimizer Hub version, please use `--version <version>` flag. The command should produce output similar to this:
```yaml
NAME: opthub
LAST DEPLOYED: Thu Apr  7 19:21:10 2022
NAMESPACE: opthub
STATUS: deployed
REVISION: 1
TEST SUITE: None
```
Advanced deployment without compilation feature.
If you want to deploy Optimizer Hub without its compilation feature, add provided `values-disable-compiler.yaml` to your helm command:
```bash
helm install opthub opthub-helm/azul-opthub -n readynow-only -f values-override.yaml -f values-disable-compiler.yaml
```

10. Verify that all started pods are ready:
```bash
kubectl get all -n opthub
```
