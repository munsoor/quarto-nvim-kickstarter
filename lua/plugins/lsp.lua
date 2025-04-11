return {

  { -- for lsp features in code cells / embedded code
    'jmbuhr/otter.nvim',
    dev = true,
    dependencies = {
      {
        'neovim/nvim-lspconfig',
        'nvim-treesitter/nvim-treesitter',
      },
    },
    opts = {},
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim' },
      { 'williamboman/mason-lspconfig.nvim' },
      { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
      { -- nice loading notifications
        -- PERF: but can slow down startup
        'j-hui/fidget.nvim',
        enabled = false,
        opts = {},
      },
      {
        {
          'folke/lazydev.nvim',
          ft = 'lua', -- only load on lua files
          opts = {
            library = {
              -- See the configuration section for more details
              -- Load luvit types when the `vim.uv` word is found
              { path = 'luvit-meta/library', words = { 'vim%.uv' } },
            },
          },
        },
        { 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
      },
      { 'folke/neoconf.nvim', opts = {}, enabled = false },
    },
    config = function()
      local lspconfig = require 'lspconfig'
      local util = require 'lspconfig.util'

      require('mason').setup()
      require('mason-lspconfig').setup {
        automatic_installation = {
          exclude = {
            'rust_analyzer',
          },
        },
      }
      require('mason-tool-installer').setup {
        ensure_installed = {
          'black',
          'stylua',
          'shfmt',
          'isort',
          'tree-sitter-cli',
          'jupytext',
        },
      }

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local function map(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          local function vmap(keys, func, desc)
            vim.keymap.set('v', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          assert(client, 'LSP client not found')

          ---@diagnostic disable-next-line: inject-field
          client.server_capabilities.document_formatting = true

          --now builtin v0.11
          -- map('gS', vim.lsp.buf.document_symbol, '[g]o so [S]ymbols')
          -- map('gD', vim.lsp.buf.type_definition, '[g]o to type [D]efinition')
          -- map('gd', vim.lsp.buf.definition, '[g]o to [d]efinition')
          -- map('K', vim.lsp.buf.hover, '[K] hover documentation')
          -- map('gh', vim.lsp.buf.signature_help, '[g]o to signature [h]elp')
          -- map('gI', vim.lsp.buf.implementation, '[g]o to [I]mplementation')
          -- map('gr', vim.lsp.buf.references, '[g]o to [r]eferences')
          -- map('<leader>ll', vim.lsp.codelens.run, '[l]ens run')
          -- map('<leader>lR', vim.lsp.buf.rename, '[l]sp [R]ename')
          -- map('<leader>lf', vim.lsp.buf.format, '[l]sp [f]ormat')
          -- vmap('<leader>lf', vim.lsp.buf.format, '[l]sp [f]ormat')
          -- map('<leader>lq', vim.diagnostic.setqflist, '[l]sp diagnostic [q]uickfix')
        end,
      })

      local lsp_flags = {
        allow_incremental_sync = true,
        debounce_text_changes = 150,
      }

      -- local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
      -- capabilities.textDocument.completion.completionItem.snippetSupport = true
      local capabilities = require('blink.cmp').get_lsp_capabilities({}, true)

      -- also needs:
      -- $home/.config/marksman/config.toml :
      -- [core]
      -- markdown.file_extensions = ["md", "markdown", "qmd"]
      lspconfig.marksman.setup {
        capabilities = capabilities,
        filetypes = { 'markdown', 'quarto' },
        root_dir = util.root_pattern('.git', '.marksman.toml', '_quarto.yml'),
      }

      lspconfig.r_language_server.setup {
        capabilities = capabilities,
        flags = lsp_flags,
        filetypes = { 'r', 'rmd', 'rmarkdown' }, -- not directly using it for quarto (as that is handled by otter and often contains more languanges than just R)
        settings = {
          r = {
            lsp = {
              rich_documentation = true,
            },
          },
        },
      }

      lspconfig.cssls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
      }

      -- lspconfig.html.setup {
      --   capabilities = capabilities,
      --   flags = lsp_flags,
      -- }

      -- lspconfig.emmet_language_server.setup {
      --   capabilities = capabilities,
      --   flags = lsp_flags,
      -- }

      lspconfig.svelte.setup {
        capabilities = capabilities,
        flags = lsp_flags,
      }

      lspconfig.yamlls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
        settings = {
          yaml = {
            schemaStore = {
              enable = true,
              url = '',
            },
          },
        },
      }

      lspconfig.jsonls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
      }

      lspconfig.dotls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
      }

      lspconfig.ts_ls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
        filetypes = { 'js', 'javascript', 'typescript', 'ojs' },
      }

      lspconfig.svelte.setup {
        capabilities = capabilities,
        flags = lsp_flags,
      }

      local function get_quarto_resource_path()
        local function strsplit(s, delimiter)
          local result = {}
          for match in (s .. delimiter):gmatch('(.-)' .. delimiter) do
            table.insert(result, match)
          end
          return result
        end

        local f = assert(io.popen('quarto --paths', 'r'))
        local s = assert(f:read '*a')
        f:close()
        return strsplit(s, '\n')[2]
      end

      local lua_library_files = vim.api.nvim_get_runtime_file('', true)
      local lua_plugin_paths = {}
      local resource_path = get_quarto_resource_path()
      if resource_path == nil then
        vim.notify_once 'quarto not found, lua library files not loaded'
      else
        table.insert(lua_library_files, resource_path .. '/lua-types')
        table.insert(lua_plugin_paths, resource_path .. '/lua-plugin/plugin.lua')
      end

      lspconfig.lua_ls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            runtime = {
              version = 'LuaJIT',
              -- plugin = lua_plugin_paths, -- handled by lazydev
            },
            diagnostics = {
              disable = { 'trailing-space' },
            },
            workspace = {
              -- library = lua_library_files, -- handled by lazydev
              checkThirdParty = false,
            },
            doc = {
              privateName = { '^_' },
            },
            telemetry = {
              enable = false,
            },
          },
        },
      }

      lspconfig.vimls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
      }

      lspconfig.julials.setup {
        capabilities = capabilities,
        flags = lsp_flags,
      }

      lspconfig.bashls.setup {
        capabilities = capabilities,
        flags = lsp_flags,
        filetypes = { 'sh', 'bash' },
      }

      -- Add additional languages here.
      -- See `:h lspconfig-all` for the configuration.
      -- Like e.g. Haskell:
      -- lspconfig.hls.setup {
      --   capabilities = capabilities,
      --   flags = lsp_flags
      -- }

      lspconfig.rust_analyzer.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = {
          'rustup',
          'run',
          'stable',
          'rust-analyzer',
        },
        -- settings = {
        --   ['rust-analyzer'] = {
        --     diagnostics = {
        --       enable = false,
        --     },
        --   },
        -- },
      }

      --
      -- See https://github.com/neovim/neovim/issues/23291
      -- disable lsp watcher.
      -- Too lags on linux for python projects
      -- because pyright and nvim both create too many watchers otherwise
      if capabilities.workspace == nil then
        capabilities.workspace = {}
        capabilities.workspace.didChangeWatchedFiles = {}
      end
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

      lspconfig.pyright.setup {
        capabilities = capabilities,
        flags = lsp_flags,
        before_init = function(_, config)
          -- Get the current Python path from the active conda/mamba environment
          local env_python = vim.fn.system('which python'):gsub('\n', '')
          local site_packages = vim.fn.system('python -c "import site; print(site.getsitepackages()[0])"'):gsub('\n', '')
          
          if env_python and site_packages then
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = env_python
            config.settings.python.analysis = config.settings.python.analysis or {}
            config.settings.python.analysis.extraPaths = { site_packages }
          end
        end,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = 'workspace',
            },
          },
        },
        root_dir = function(fname)
          return util.root_pattern('.git', 'setup.py', 'setup.cfg', 'pyproject.toml', 'requirements.txt')(fname)
        end,
      }
    end,
  },
}
