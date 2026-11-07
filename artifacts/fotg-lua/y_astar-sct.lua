-- Adapted ASTAR Pathfinding --
    -- ======================================================================
    -- Copyright (c) 2012 RapidFire Studio Limited 
    -- All Rights Reserved. 
    -- http://www.rapidfirestudio.com

    -- Permission is hereby granted, free of charge, to any person obtaining
    -- a copy of this software and associated documentation files (the
    -- "Software"), to deal in the Software without restriction, including
    -- without limitation the rights to use, copy, modify, merge, publish,
    -- distribute, sublicense, and/or sell copies of the Software, and to
    -- permit persons to whom the Software is furnished to do so, subject to
    -- the following conditions:

    -- The above copyright notice and this permission notice shall be
    -- included in all copies or substantial portions of the Software.

    -- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    -- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    -- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONASTAR.INFRINGEMENT.
    -- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    -- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    -- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    -- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    -- ======================================================================

    --module ( "astar", package.seeall )

----------------------------------------------------------------
-- local variables
----------------------------------------------------------------

ASTAR = {cachedPaths = nil}

----------------------------------------------------------------
-- local functions

    function ASTAR:neighbor_nodes ( theNode, nodes, node_is_valid )
        local neighbors = {}
        for _, node in ipairs ( nodes ) do
            if theNode ~= node and node_is_valid ( theNode, node ) then
                table.insert ( neighbors, node )
            end
        end
        return neighbors
    end

    function ASTAR:not_in ( set, theNode )
        for _, node in ipairs ( set ) do
            if node == theNode then return false end
        end
        return true
    end

    function ASTAR:remove_node ( set, theNode )
        for i, node in ipairs ( set ) do
            if node == theNode then 
                set [ i ] = set [ #set ]
                set [ #set ] = nil
                break
            end
        end	
    end

    function ASTAR:unwind_path ( flat_path, map, current_node )
        if map [ current_node ] then
            table.insert ( flat_path, 1, map [ current_node ] ) 
            return self:unwind_path ( flat_path, map, map [ current_node ] )
        else
            return flat_path
        end
    end

----------------------------------------------------------------
-- pathfinding functions

    function ASTAR:a_star ( nodes, start, goal_node_or_function, is_valid_node_func )

        local closedset = {}
        local openset = { start }
        local came_from = {}

        local g_score, f_score = {}, {}
        g_score [ start ] = 0
        f_score [ start ] = g_score [ start ] + 1

        while #openset > 0 do

            local current = openset[1]

            --if goal is end node
            if type(goal_node_or_function) == "table" then
                local goal = goal_node_or_function
                if current == goal then
                    local path = self:unwind_path ( {}, came_from, goal )
                    table.insert ( path, goal )
                    return path
                end
            end
            --if goal is to find a node with a given property
            if type(goal_node_or_function) == "function" then
                if goal_node_or_function(current) then
                local path = self:unwind_path ( {}, came_from, current )
                    table.insert ( path, current )
                    return path
                end
            end

            self:remove_node ( openset, current )		
            table.insert ( closedset, current )

            local neighbors = self:neighbor_nodes ( current, nodes, is_valid_node_func )
            for _, neighbor in ipairs ( neighbors ) do 
                if self:not_in ( closedset, neighbor ) then

                    local tentative_g_score = g_score [ current ] + 1

                    if self:not_in ( openset, neighbor ) or tentative_g_score < g_score [ neighbor ] then 
                        came_from 	[ neighbor ] = current
                        g_score 	[ neighbor ] = tentative_g_score
                        f_score 	[ neighbor ] = g_score [ neighbor ] + 1
                        if self:not_in ( openset, neighbor ) then
                            table.insert ( openset, neighbor )
                        end
                    end
                end
            end

        end

        return nil -- no valid path

    end

----------------------------------------------------------------
-- exposed functions

    function ASTAR:clear_cached_paths ()
        self.cachedPaths = nil
    end

    function ASTAR:path ( start, goal, nodes, is_valid_node_func, ignore_cache )

        if not self.cachedPaths then self.cachedPaths = {} end
        if not self.cachedPaths [ start ] then
            self.cachedPaths [ start ] = {}
        elseif self.cachedPaths [ start ] [ goal ] and not ignore_cache then
            return self.cachedPaths [ start ] [ goal ]
        end

        local resPath = ASTAR:a_star ( start, goal, nodes, is_valid_node_func )
        if not self.cachedPaths [ start ] [ goal ] and not ignore_cache then
            self.cachedPaths [ start ] [ goal ] = resPath
        end

        return resPath

    end