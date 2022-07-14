#No se levanta correctamente el nodo de kubernetes.
swapoff -a                 # Disable all devices marked as swap in /etc/fstab
sed -e '/swap/ s/^#*/#/' -i /etc/fstab   # Comment the correct mounting point
systemctl mask swap.target               # Completely disabled