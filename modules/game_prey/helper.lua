local Helper = {}

function Helper.handleFormatPrice(price)
    local priceText = "Free"
    if price > 0 then
        if price >= 1000000 then
            local millions = math.floor(price / 1000000)
            local remainder = price % 1000000
            if remainder >= 500000 then
                priceText = string.format('%d.5 M', millions)
            elseif remainder >= 100000 then
                priceText = string.format('%d M', millions)
            else
                priceText = string.format('%d M', math.max(1, millions))
            end
        elseif price >= 100000 then
            local thousands = math.floor(price / 1000)
            local remainder = price % 1000
            if remainder >= 500 then
                priceText = string.format('%d.5 k', thousands)
            elseif remainder >= 100 then
                priceText = string.format('%d k', thousands)
            else
                priceText = string.format('%d k', math.max(1, thousands))
            end
        else
            priceText = tostring(price)
        end
    end

    return priceText
end

return Helper
