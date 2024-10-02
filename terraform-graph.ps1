terraform graph | Out-File -Encoding ASCII graph.dot
dot -Tpng graph.dot -o graph.png