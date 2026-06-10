local util = require('lspconfig.util')

vim.filetype.add({ filename = { Config = "brazil-config" } })

-- Taken from https://w.amazon.com/bin/view/Barium/#Hnvim-lspconfig.
return {
  default_config = {
    cmd = {'barium'};
    filetypes = {'brazil-config'};
    root_dir = function(fname)
      return util.find_git_ancestor(fname)
    end;
    settings = {};
  };
}
