return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>mp",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = function()
		-- Function to find the project's ruleset file
		local function find_project_ruleset()
			local files_to_check = {
				"phpcs.xml",
				"phpcs.xml.dist",
				".phpcs.xml",
				".phpcs.xml.dist",
				"ruleset.xml",
			}

			-- Start from the current file's directory and move up
			local current_dir = vim.fn.expand("%:p:h")
			local home_dir = vim.fn.expand("$HOME")

			while current_dir ~= "" and current_dir ~= home_dir do
				for _, file in ipairs(files_to_check) do
					local ruleset_path = current_dir .. "/" .. file
					if vim.fn.filereadable(ruleset_path) == 1 then
						return ruleset_path
					end
				end
				-- Move up one directory
				current_dir = vim.fn.fnamemodify(current_dir, ":h")
			end
			return nil
		end

		-- Function to get proper phpcbf arguments
		local function get_phpcbf_args()
			local ruleset = find_project_ruleset()
			if ruleset then
				return {
					"--standard=" .. ruleset,
					"-",
				}
			else
				return {
					"--standard=WordPress",
					"-",
				}
			end
		end

		return {
			formatters_by_ft = {
				php = { "phpcbf" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				liquid = { "prettier" },
				lua = { "stylua" },
			},
			formatters = {
				phpcbf = {
					command = "phpcbf",
					args = function(ctx)
						return get_phpcbf_args()
					end,
					stdin = true,
					cwd = function(ctx)
						return vim.fn.expand("%:p:h")
					end,
				},
			},
			format_on_save = {
				timeout_ms = 5000,
				async = false,
				quiet = false,
				lsp_fallback = true,
			},
		}
	end,
}
