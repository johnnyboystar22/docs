---
type: docs
title: "Deploy the application with the frontend service and database"
linkTitle: "Author and deploy app"
description: "Author and deploy the application"
weight: 2000
slug: "application"
---

## Download the source code

The tutorial source code will contain the app templates and frontend code for this tutorial.

{{< tabs "ZIP Download" "GitHub Codespace" "Git Clone" >}}

{{% codetab %}}
Download and unzip `tutorial.zip`:
{{< button link="https://get.radapp.dev/code/edge/tutorial.zip" text="Download tutorial.zip" >}}
{{% /codetab %}}

{{% codetab %}}
In the [preconfigured Codespace]({{< ref getting-started >}}) you can `cd` into the `tutorial` directory:
```bash
cd tutorial
```
{{% /codetab %}}

{{% codetab %}}
Clone the [project-radius/samples](https://github.com/project-radius/samples) repository:
```bash
git clone https://github.com/project-radius/samples.git
cd samples/tutorial
```
{{% /codetab %}}

{{< /tabs >}}

The tutorial directory contains three [Bicep]({{< ref bicep >}}) files:

1. **app.bicep** - Contains the app definition
1. **mongo-container.bicep** - Contains the definition for deploying mongo container
1. **azure-cosmosdb.bicep** - Contains the definition for Azure cosmosdb

## Defining a Radius application

Let's dig into the `app.bicep` to understand the input parameters and `Applications.Core/applications` resource. The application acts as the container for all of your application services, infrastructure, and relationships. It's the top-level resource a developer will model and configure.

{{< rad file="snippets/app.bicep" embed=true marker="//APPBASE" >}}

Within the application resource, the **environment** property specifies the environmentId to deploy the application and other resources into. Since this was initialized in the previous step via the CLI, `rad deploy` will automatically inject the `environment` parameter into the Bicep file during deployment.

The **location** property defines where to deploy a resource within the targeted platform. For self-hosted Kubernetes environments this value must be set to `'global'`. See [Resource Schema]({{< ref resource-schema >}}) for more info.

## Container and route

Next, let's look into the definition for the website's frontend container.

Radius captures the relationships and intentions behind an application, which simplifies deployment and management. The `frontend` and `frontendRoute` resources in your Bicep file will contain everything needed for the website frontend to run and expose a port to the internet.

The **`frontend`** [container]({{< ref container >}}) resource specifies:

- **application**: The application to which this container belongs. The ID of the application defined above is used.
- **container image**: The container image to run. This is where your website's front end code lives.
- **container ports**: The ports to expose on the container, along with the [HttpRoute]({{< ref httproute >}}) that will be used to access the container.
- **connections**: The connections to make to other resources. In this case, the frontend container will connect to the backing database. This is described further in the next paragraph.

{{< rad file="snippets/app.bicep" embed=true marker="//CONTAINER" >}}

## Gateway

The **`gateway`** resource is how users will interact with your frontend container. The [Gateway]({{< ref gateway >}})  specifies:

- **application**: The application to which this gateway belongs. The ID of the application defined above is used.
- **routes**: The routes handled by this gateway. Here, we specify that `'/'` should map to `frontendRoute`, which is provided by the `frontend` container.

{{< rad file="snippets/app.bicep" embed=true marker="//GATEWAY" >}}

## Links

A [Radius link]({{< ref link-schema >}}) provides an abstraction for an infrastructure resource through its API, allowing the backing resource type to be swapped out without changing the way the consuming resource is defined. In this example, a developer can first use a containerized Mongo DB as the app's database when deploying to their dev environment. Later, the infrastructure admin can use an Azure Cosmos DB for MongoDB as the app's database when deploying to production.

<img src="mongo-link.png" width=450px alt="Diagram of a mongo link" /><br />

To learn more about links visit the [concepts docs]({{< ref appmodel-concept >}}).

### Containerized Mongo DB

Let's look at a Mongo DB backed by a Mongo Kubernetes StatefulSet and Service within `mongo-container.bicep`:

{{< rad file="snippets/mongo-container.bicep" embed=true marker="//MONGO" replace-key-ss="//SS" replace-value-ss="resource statefulset 'apps/StatefulSet@v1' = {...}" replace-key-service="//SERVICE" replace-value-service="resource service 'core/Service@v1' = {...}" >}}

The mongo container definition is then referenced within `app.bicep` as a [Bicep module](https://docs.microsoft.com/azure/azure-resource-manager/bicep/modules):

{{< rad file="snippets/app.bicep" embed=true marker="//MONGOMODULE" >}}

### Mongo link

Now that you have modeled your infrastructure, look how the `Applications.Link/mongoDatabases` link is built using the `connectionString` output:

{{< rad file="snippets/app.bicep" embed=true marker="//DATABASE LINK" >}}

### Connect to `db` from `frontend`

Once the `db` link is defined, you can reference it in the [`connections`]({{< ref appmodel-concept >}}) section of the `frontend` resource, as shown above.

[Connections]({{< ref appmodel-concept >}}) are used to configure relationships between the source container and the target resource. This declares the *intention* from the `frontend` container to communicate with the `db` resource.

Now that you have created a connection called `itemstore`, environment variables with connection information will be injected into the `frontend` container. The container reads the database connection string from an environment variable named `CONNECTION_ITEMSTORE_CONNECTIONSTRING`.

Connections automatically inject connection data into containers as environment variables. The name of the environment variable is the connection name in all caps, prefixed with `CONNECTION_`. For example, the connection named `itemstore` will inject the variable `CONNECTION_ITEMSTORE_CONNECTIONSTRING` with the connection string from `db`. Learn more in the [connections docs]({{< ref appmodel-concept >}}).

## Deploy the application

Now you are ready to deploy the application for the first time:

1. Make sure you have an [Radius environment initialized]({{< ref 1-tutorial-environment >}}).

1. Deploy to your Radius environment via the rad CLI:

   ```sh
   rad deploy ./app.bicep
   ```

   This will deploy the application into your environment and launch the container resource for the frontend website. You should see the following resources deployed at the end of `rad deploy`:

   ```
   Deployment In Progress:

     Completed       webapp                     Applications.Core/applications
     Completed       frontend                   Applications.Core/containers
     Completed       http-route                 Applications.Core/httpRoutes
     Completed       public                     Applications.Core/gateways
     Completed       mongo-module               Microsoft.Resources/deployments
     Completed       db                         Applications.Link/mongoDatabases

   Deployment Complete 
   ```
1. Get the public endpoint address for the gateway:

   A public endpoint will also be available to your application from the [Gateway]({{< ref gateway >}}) resource. Use [`rad app status`]({{< ref rad_application_status >}}) to get the endpoint:
   ```bash
   rad app status -a webapp
   ```
1. To test your application, navigate to the public endpoint:

   <img src="todoapp.png" width="400" alt="screenshot of the todo application">

   {{% alert title="⚠️ Caution" color="warning" %}}
   If you are unable to connect to webapp in your browser, make sure your organization does not block HTTP traffic to your Kubernetes cluster. You may need to be on your corporate network or use a jumpbox. As a workaround, you can run `rad resource expose containers frontend -a webapp --port 3000` to [port-forward the frontend container]({{< ref rad_resource_expose >}}) to your local machine. Then, you can access the application at `http://localhost:3000`.
   {{% /alert %}}

   You can play around with the application's features:

   - Add a todo item
   - Mark a todo item as complete
   - Delete a todo item

## Next step: Moving to production on Azure

When moving to production, you may want to swap your locally running container for an Azure CosmosDB for your Mongo database. The next step will show you how to swap your link infrastructure to an Azure resource, leveraging the Azure [cloud provider]({{< ref providers >}}).

<br> {{< button text="Previous: Initialize an environment" page="1-tutorial-environment" newline="false" >}}{{< button text="Next: Swap link resource (optional)" page="3-tutorial-link" >}} 