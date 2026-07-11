class_name BirdEncyclopediaData
extends Resource

@export_group("Informações Científicas")
@export var scientific_name: String = ""
@export var popular_names: Array[String] = []
@export var english_name: String = ""
@export var conservation_status: String = "" # Ex: Pouco Preocupante (LC), Vulnerável (VU)

@export_group("Biologia, Habitat")
@export_multiline var diet: String = ""
@export_multiline var habitats: String = "" # Locais onde é encontrado

@export_group("Distribuição Geográfica (Brasil) e Curiosidades")
@export var region_north: bool = false
@export var region_northeast: bool = false
@export var region_central_west: bool = false
@export var region_southeast: bool = false
@export var region_south: bool = false
@export_multiline var curiosity: String = ""
