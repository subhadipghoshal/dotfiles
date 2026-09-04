-- For Neovim windows to show the open file/directory instead of just "nvim", Neovim itself
-- needs `'title'` enabled and a `titlestring` that includes what you want to see

vim.opt.title = true
vim.opt.titlestring = "%t %m (%{expand('%:~:h')})"
