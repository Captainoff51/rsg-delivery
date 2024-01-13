local Translations = {
    error = {
        failed_del = 'Échec de la livraison',
        failed_del_descr = 'vous avez manqué de temps, la mission a échoué',
    },
    success = {
        success_del = 'Livraison réussie',
        success_del_descr = 'vous avez terminé votre livraison',
    },
    primary = {
        delivery_loc1 = 'Livraison Saint-Valentin',
        delivery_loc2 = 'Livraison Blackwater',
        delivery_loc3 = 'Livraison de fraises',
        delivery_loc4 = 'Livraison au ranch',
        delivery_loc5 = 'Livraison de Tumbleweed',
        delivery_loc6 = 'Le long terme',
        delivery_loc7 = 'La ruée vers le pétrole',
    },
    menu = {
        menu_var = 'Exemple de Texte',
    },
    label = {
        delivery_blip = 'Tâche de livraison',
        delivery_time = 'Délai de livraison restant : ',
        delivery_point = 'POINT DE LIVRAISON',
       
    },
}

if GetConvar('rsg_locale', 'en') == 'fr' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
