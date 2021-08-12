class TABLE

    new: (t) => @t = t

    -- makes arithmetic operations on a table
    arithmetic_op: (fn = ((v) -> v), operation = "+") =>
        result = 0
        for k, v in ipairs @t
            switch operation
                when "+", "sum" then result += fn v
                when "-", "sub" then result -= fn v
                when "*", "mul" then result *= fn v
                when "/", "div" then result /= fn v
                when "%", "rem" then result %= fn v
                when "^", "exp" then result = result ^ fn v
        return result

    -- makes a shallow copy of an table
    copy: => {k, type(v) == "table" and (type(k) != "number" and v or TABLE(v)\copy!) or v for k, v in pairs @t}

    -- concatenates values to the end of the table
    concat: (...) =>
        t = @copy!
        for val in *{...}
            if type(val) == "table"
                for k, v in pairs val
                    t[#t + 1] = v if type(k) == "number"
            else
                t[#t + 1] = val
        return t

    -- creates a new table populated with the results of calling a provided function on every element in the calling table
    map: (fn) => {k, fn(v, k, @t) for k, v in pairs @t}

    -- adds one or more elements to the end of the table
    push: (...) =>
        n = select("#", ...)
        for i = 1, n
            @t[#@t + 1] = select(i, ...)
        return ...

    -- executes a reducer function on each element of the table
    reduce: (fn, init) =>
        acc = init
        for k, v in pairs @t
            acc = (k == 1 and not init) and v or fn(acc, v) -- (accumulator, current_value)
        return acc

    -- Reverses all table values
    reverse: => [@t[#@t + 1 - i] for i = 1, #@t]

    -- returns a copy of part of an table from a subarray created between the start and end positions
    slice: (f, l, s) => [@t[i] for i = f or 1, l or #@t, s or 1]

    -- changes the contents of an table by removing or replacing existing elements and/or adding new elements
    splice: (start, delete, ...) =>
        args, removes, t_len = {...}, {}, #@t
        n_args, i_args = #args, 1
        start = start < 1 and 1 or start
        delete = delete < 0 and 0 or delete
        if start > t_len
            start = t_len + 1
            delete = 0
        delete = start + delete - 1 > t_len and t_len - start + 1 or delete
        for pos = start, start + math.min(delete, n_args) - 1
            table.insert(removes, @t[pos])
            @t[pos] = args[i_args]
            i_args += 1
        i_args -= 1
        for i = 1, delete - n_args
            table.insert(removes, table.remove(@t, start + i_args))
        for i = n_args - delete, 1, -1
            table.insert(@t, start + delete, args[i_args + i])
        return removes

    -- inserts new elements at the start of an table, and returns the new length of the table
    unshift: (...) =>
        args = {...}
        for k = #args, 1, -1
            table.insert(@t, 1, args[k])
        return #@t

    -- returns a string with the contents of the table
    view: (table_name = "table_unnamed", indent = "") =>
        cart, autoref = "", ""
        isemptytable = (t) -> next(t) == nil
        basicSerialize = (o) ->
            so = tostring(o)
            if type(o) == "function"
                info = debug.getinfo o, "S"
                return format "%q", so .. ", C function" if info.what == "C"
                format "%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source
            elseif (type(o) == "number") or (type(o) == "boolean")
                return so
            format "%q", so
        addtocart = (value, table_name, indent, saved = {}, field = table_name) ->
            cart ..= indent .. field
            if type(value) != "table"
                cart ..= " = " .. basicSerialize(value) .. ";\n"
            else
                if saved[value]
                    cart ..= " = {}; -- #{saved[value]}(self reference)\n"
                    autoref ..= "#{table_name} = #{saved[value]};\n"
                else
                    saved[value] = table_name
                    if isemptytable(value)
                        cart ..= " = {};\n"
                    else
                        cart ..= " = {\n"
                        for k, v in pairs value
                            k = basicSerialize(k)
                            fname = "#{table_name}[ #{k} ]"
                            field = "[ #{k} ]"
                            addtocart v, fname, indent .. "	", saved, field
                        cart = "#{cart}#{indent}};\n"
        return "#{table_name} = #{basicSerialize(@t)}" if type(@t) != "table"
        addtocart @t, table_name, indent
        return cart .. autoref

{:TABLE}