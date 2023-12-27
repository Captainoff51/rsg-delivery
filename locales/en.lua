local Translations = {
    error = {
        failed_del = 'Delivery Failed',
        failed_del_descr = 'you ran out of time, mission failed',
    },
    success = {
        success_del = 'Delivery Sucessful',
        success_del_descr = 'you completed your delivery',
    },
    primary = {
        delivery_loc1 = 'Valentine Delivery',
        delivery_loc2 = 'Blackwater Delivery',
        delivery_loc3 = 'Strawberry Delivery',
        delivery_loc4 = 'Ranch Delivery',
        delivery_loc5 = 'Tumbleweed Delivery',
        delivery_loc6 = 'The Long Run',
        delivery_loc7 = 'The Oil Run',
    },
    menu = {
        menu_var = 'Example Text',
    },
    label = {
        delivery_blip = 'Delivery Job',
        delivery_time = 'Delivery Time Remaining: ',
        delivery_point = 'DELIVERY POINT',
       
    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
