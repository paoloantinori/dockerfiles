//based on 
// https://github.com/stormgrind/cirras-rpm/blob/master/src/import-servers.js and 
// http://boxgrinder.org/blog/2010/01/29/rhq-cli-configuring-and-importing-resources/


var jboss_fuse_containers = findResources("JBoss Fuse Container");

print("Already imported JBoss Fuse Containers:\n");
printServers(jboss_fuse_containers);
print("\n")

jboss_fuse_containers = findResources("JBoss Fuse Container", false);

print("Discovering new JBoss Fuse Containers:\n");
printServers(jboss_fuse_containers);
print("\n")


var rhq_agents = findResources("RHQ Agent");

print("Already imported RHQ Agents:\n");
printServers(rhq_agents);
print("\n")

rhq_agents = findResources("RHQ Agent", false);

print("Discovering new RHQ Agents:\n");
printServers(rhq_agents);
print("\n")


// importing discovered containers
if (jboss_fuse_containers != null && jboss_fuse_containers.size() > 0) {
    print("Discovered " + jboss_fuse_containers.size() + " JBoss Fuse Containers:\n");

    var containerResourceIds = [];

    for (i = 0; i < jboss_fuse_containers.size(); i++) {
        var discovered_container = jboss_fuse_containers.get(i);

        addDependencyIds(discovered_container, containerResourceIds);

        print(" - " + discovered_container.name + "\n");
        print(" Reconfiguring agent...\n");

        var address = discovered_container.name.match(new RegExp("^[\\w\\-\\.]+", "g"))[0];
        var containerPlugin = ProxyFactory.getResource(discovered_container.id);
        var containerPluginConfig = containerPlugin.getPluginConfiguration();

        //containerPluginConfig.getSimple("url").setStringValue("http://" + address);
        //containerPlugin.updatePluginConfiguration(containerPluginConfig);

        print(" Agent reconfigured.\n");
    }

    print("Importing " + jboss_fuse_containers.size() + " JBoss Fuse Containers...\n");
    DiscoveryBoss.importResources(containerResourceIds);
    print("Imported.\n");

} else {
    print("No servers found.\n")
}


function findResources(name, imported) {
    imported = typeof(imported) != 'undefined' ? imported : true;

    var criteria = new ResourceCriteria();

    criteria.addFilterResourceTypeName(name);

    if (!imported) {
        criteria.addFilterInventoryStatus(InventoryStatus.NEW);
    }

    return ResourceManager.findResourcesByCriteria(criteria);
}

function printServers(resources) {
    if (resources != null && resources.size() > 0) {
        for (var i = 0; i < resources.size(); i++) {
            var resource = resources.get(i);
            print(" - " + resource.name);
        }
    } else {
        print("No servers found.")
    }
}

function addDependencyIds(resource, array) {
    var parentResource = ResourceManager.getResource(resource.id).getParentResource();

    if (parentResource != null) {
        parentResource = ResourceManager.getResource(parentResource.id);

        if (parentResource.getInventoryStatus().equals(InventoryStatus.NEW))
            addDependencyIds(parentResource, array);
    }

    array.push(resource.id);
}

