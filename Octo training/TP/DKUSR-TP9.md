# Docker / Kubernetes - TP9 : Sans fillet !
> **Objectifs du TP** :
>- Déployer une application simple en utilisant plusieurs resources de base

>
> **Niveau de difficulté** :
> Intermédiaire

## 1- Introduction

Au programme de ce TP, nous allons déployer "from scratch" une application

## 2- Supprimer toutes vos resources précédentes
De la manière la plus adaptée selon vous

## 3- Création des objets Kubernetes

- Créer un fichier `nginx.yml` qui contiendra votre topology kubernetes 
- Créer un service exposant 2 pods s'appelant "nginx" (utilisant l'image `nginx:1.19`) accessible depuis internet sur l'URL : http://nginx-gula.52.47.206.36.ip.aws.octo.training
- Personnaliser la page HTML par défaut de nginx (via quelle ressource ?)
- Utiliser une resource HPA pour scaler les pods automatiquements de 2 à 5 en fonction du CPU 

> **Questions**
>- Quelles sont les resources qu'il va falloir créer ?
