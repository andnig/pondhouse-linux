local M = {}

M.create_buffer_with_name = function()
    local buffer_name = vim.fn.input("Enter new buffer name: ")
    if buffer_name ~= "" then
        vim.cmd("edit " .. buffer_name)
    else
        print("No buffer name provided.")
    end
end

M.create_new_note = function(note_type)
    local note_name = vim.fn.input("Enter new note name: ")
    if note_name ~= "" then
        vim.cmd("edit ~/.notes/reference/" .. note_type .. "/" .. note_name .. ".md")
    else
        print("No note name provided.")
    end
end

return M
