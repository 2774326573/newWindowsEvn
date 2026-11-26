-- Generated runtime paths are replaced by scripts/install.py.
local M = {}
local python = @@PYTHON@@
local helper = @@HELPER@@

function M:peek(job)
    local cache = ya.file_cache(job)
    if not cache then return end
    if not fs.cha(cache) then
        local output, err = Command(python)
            :arg({ helper, tostring(job.file.path), tostring(cache), tostring(job.skip + 1) })
            :stdout(Command.PIPED):stderr(Command.PIPED):output()
        if not output then
            return ya.preview_widget(job, Err("Preview helper unavailable: %s", err))
        elseif not output.status.success then
            return ya.preview_widget(job, ui.Text(output.stderr):area(job.area))
        end
        local bound = tonumber(output.stdout:match("BOUND:(%d+)"))
        if bound then
            return ya.emit("peek", { bound - 1, only_if = job.file.url, upper_bound = true })
        end
    end
    local _, err = ya.image_show(cache, job.area)
    ya.preview_widget(job, err)
end

function M:seek(job)
    local hovered = cx.active.current.hovered
    if hovered and hovered.url == job.file.url then
        ya.emit("peek", { math.max(0, cx.active.preview.skip + ya.clamp(-1, job.units, 1)), only_if = job.file.url })
    end
end

return M
