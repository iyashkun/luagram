print("Testing Luagram installation...")

local success, luagram = pcall(require, "luagram")
if not success then
    print("ERROR: Could not load luagram module")
    print("Error:", luagram)
    os.exit(1)
end

print("✓ Luagram module loaded successfully")

local components = {
    "Client",
    "types", 
    "filters",
    "handlers",
    "errors"
}

for _, component in ipairs(components) do
    if luagram[component] then
        print("✓ " .. component .. " available")
    else
        print("✗ " .. component .. " missing")
    end
end

local test_success, test_client = pcall(function()
    return luagram.Client.new("test_token", {})
end)

if test_success then
    print("✓ Client creation successful")
else
    print("✗ Client creation failed:", test_client)
end

print("Luagram installation test completed!")
