return {

  { 
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        --markdown = { 'markdownlint' },
        fortran = { 'gfortran' },
        python = { 'flake8' },
      }

      -- https://fortran-lang.discourse.group/t/linter-for-nvim/8088/12
      local pattern = '^([^:]+):(%d+):(%d+):%s+([^:]+):%s+(.*)$'
      local groups = { 'file', 'lnum', 'col', 'severity', 'message' }
      local severity_map = {
        ['Error'] = vim.diagnostic.severity.ERROR,
        ['Warning'] = vim.diagnostic.severity.WARN,
      }
      local defaults = { ['source'] = 'gfortran' }
      local gfortran_diagnostic_args = { '-Wall', '-Wextra', '-fmax-errors=5', '-cpp' }
      local required_args = { '-fsyntax-only', '-fdiagnostics-plain-output', '-J/tmp' }
      local args = vim.list_extend(required_args, gfortran_diagnostic_args)

      lint.linters.gfortran = {
        cmd = 'gfortran',
        stdin = false,
        append_fname = true,
        stream = 'stderr',
        env = nil,
        args = args,
        ignore_exitcode = true,
        parser = require('lint.parser').from_pattern(pattern, groups, severity_map, defaults),
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
