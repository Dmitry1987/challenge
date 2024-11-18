Using k3s for test (never used it until now, but lazy to install minikube on my windows machine again so trying this one in WSL2)

1. Install k3s
2. Run these to install the chart 
```
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
k3s kubectl create namespace web
helm upgrade --install --create-namespace -n web --set web.replicas=3 -f ./helm/webserver/values.yaml  webserver ./helm/webserver
```

You'll see this if successfull: 
```
NAME: webserver
LAST DEPLOYED: Mon Nov 18 20:41:11 2024
NAMESPACE: web
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

3. Check the ingress rule and the pods 
```
kubectl get ingress -n web
kubectl get pods -n web
```

In my case it's this IP: 
```
NAME            CLASS     HOSTS   ADDRESS          PORTS   AGE
webserver-web   traefik   *       172.19.235.144   80      12s
```
Try to reach it with `curl 172.19.235.144` and see the response of the python container.  Works in my case, but can't guarantee anything :D  (I'm on windows 11, with latest k3s that was just installed today).

4. Generate helm docs if needed like this:
```
docker run --rm --volume "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:latest

time="2024-11-18T20:12:15Z" level=info msg="Found Chart directories [helm/webserver]"
time="2024-11-18T20:12:15Z" level=info msg="Generating README Documentation for chart helm/webserver"
```
