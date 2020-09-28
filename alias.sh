alias c="bash curlPython.sh"

alias k="kubectl"
alias kgp="kubectl get pods -o wide"
alias kgpn="kubectl get pods -n"
alias kgpa="kubectl get pods -o wide --all-namespaces"
alias kgd="kubectl get deployments"
alias kgs="kubectl get services"
alias ke="kubectl exec -it"

function keb {
  kubectl exec -it $1 bash || kubectl exec -it $1 sh
}

function kebn {
  kubectl exec -it $1 -n $2 bash || kubectl exec -it $1 -n $2 sh
}