


# Getting Started

## Prerequisites

Node.js 22+ and npm 10+

## Local Development Setup

1. Clone the repository (if not already cloned)
   ```bash
   git clone git@github.com:cryptovoxels/cryptovoxels.git
   cd cryptovoxels
   ```

2. Copy environment file
   ```bash
   cp .env.example .env
   ```

3. Configure `.env` - Ask for credentials
   ```bash
   DATABASE_URL=postgresql://doadmin:<PASSWORD>@db-voxels-follower-do-user-554845-0.j.db.ondigitalocean.com:25060/defaultdb?sslmode=require
   JWT_SECRET="<secret-value>"
   ```

4. Install and start Redis (optional - needed for multiplayer/chat)
   ```bash
   brew install redis
   brew services start redis
   redis-cli ping  # Should return PONG
   ```

   Add to `.env`:
   ```bash
   REDIS_URL=redis://localhost:6379
   ```

5. Install dependencies
   ```bash
   npm install
   ```

6. Build workspace packages
   ```bash
   npm run build:workspaces
   ```

7. Create `packages/mp-server/.env` with same credentials as root `.env`
   ```bash
   cat > packages/mp-server/.env << EOF
   JWT_SECRET="<secret-value>"
   REDIS_URL=redis://localhost:6379
   DATABASE_URL=postgresql://doadmin:<PASSWORD>@db-voxels-follower-do-user-554845-0.j.db.ondigitalocean.com:25060/defaultdb?sslmode=require
   EOF
   ```

8. Start development server
   ```bash
   npm run dev         # Hot reload (better for SSR editing)
   npm run dev:stable  # No server restart 
   ```

9. Open http://localhost:9000

## Optional: Blockchain Features (Alchemy)

Required for NFT/parcel ownership, wearables, and wallet features. Free tier is sufficient.

1. Create account at https://www.alchemy.com/ (no credit card required)

2. Create two apps:
   - Ethereum Mainnet app
   - Polygon Mainnet app

3. Get API keys from each app and add to `.env`:
   ```bash
   ALCHEMY_ETH_API_KEY=your_ethereum_key
   ALCHEMY_MATIC_API_KEY=your_polygon_key
   ```

4. Restart dev server

## Expected Errors

If you skip Redis or Alchemy setup, you'll see these errors (safe to ignore for basic development):

- `Error from redis client: ECONNREFUSED` - Redis not running
- `Alchemy provider error: Must be authenticated!` - Missing Alchemy keys

## Troubleshooting

Check Redis is running:
```bash
redis-cli ping  # Should return PONG
```

Restart Redis:
```bash
brew services restart redis
```

For advanced setup (local database, SSL for WebXR), see [meta/onboarding.md](https://github.com/cryptovoxels/meta/blob/main/onboarding.md#setting-up-web-server-and-multiplayer-locally-cryptovoxels--shard)

# Break down of folders:

#### dist/

Static files hosted publicly.

#### models/

Weird replica of `dist`, probably can delete

#### server/

Express server that uses postgres to store data, and also the websocket multiuser stuff. Renders some of `web` content using server side rendering.

#### src/

Babylon.js web client.

#### textures/

Weird replica of `dist`, probably can delete

#### vendor/

Vendored version of `structly` npm package - not sure if needed

#### web/

Web content rendered using preact. Some is server rendered, some only works on client.

# Deps

- postresql
- postgis

# Codeformatting

To batch format everything use `npm run format`

## Editorconfig

To keep the code consistent, and the changes easier to read, the code is formatted with [.editorconfig](https://editorconfig.org/).
This process should be automatic, so that we poor developers don't need to think about code style standards.

The following code editor easily supports .editorconfig

- IntelliJ editors (idea, phpstorm, webstorm etc)
- VSCode via https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig
- sublime text via https://github.com/sindresorhus/editorconfig-sublime#readme
- other editors check https://editorconfig.org/#download

## Prettier

We use https://prettier.io/ for an opinionated codestyle across the whole project. Can be used by either batch running
`npm run prettier` or per individual files or directories as `npx prettier ./src/index.ts --write`

## Spy

Some function happening too often? Spy on it:

    function Spy (obj, method) {
      const proxy = obj[method]
      obj[method] = function() {
        console.log(arguments)
        let args = [].slice.apply(arguments)
        const res = proxy.call(obj, ...args)
        return res
      }
    }

## Fixing broken wearable minting

Sometimes something breaks and wearables don't get minted properly. They're minted, but we don't have the token_id set in our database, so the wearables appears 'broken' on opensea - this is how to fix it:

Go to the wearables contract on etherscan:

    https://etherscan.io/address/0xa58b5224e2fd94020cb2837231b2b0e4247301a6

Go to the txns page:

    https://etherscan.io/txs?a=0xa58b5224e2fd94020cb2837231b2b0e4247301a6

Find your mint transactions - eg this is a single mint txn:

    https://etherscan.io/tx/0x749b9f7f4ba9d85645341eada309de156e1a6b1441ed2457cee5699d5ebd1cc1

Go to the logs page and copy the vox URL hash - eg:

    https://www.cryptovoxels.com/w/66cf7a6da881c3df42d06d49b8cddb5df6328384/vox -> 66cf7a6da881c3df42d06d49b8cddb5df6328384

Get the token_id - eg:

    3118

Now construct this sql.

    update wearables set token_id=3118 where hash='66cf7a6da881c3df42d06d49b8cddb5df6328384';
    ...

Repeat this process to generate a multi-line sql query. Post it in #general and get someone to review your sql.

Run the queries in production.

Now request this URL for each wearable (in this example 3118) - to force opensea to update:

    https://api.opensea.io/api/v1/asset/0xa58b5224e2fd94020cb2837231b2b0e4247301a6/3118?force_update=true
    ...

Fetch all those URLs, wait 30 seconds, and wearables are fixed.

## Databases

If on windows - use the follower (it's a copy of the public database that you can use without installing
postgres locally on windows because fuck that for a laugh). You'll need the follower `PASSWORD`.

  DATABASE_URL=postgres://dramallama:PASSWORD@follower.cryptovoxels.com:5432/cryptovoxels npm start

On mac - try local db:

1. Install postgres and postgis (with brew probably)
2. `createdb cryptovoxels` 
3. `psql cryptovoxels` then `create role root superuser` then `create extension postgis`
4. `ssh root@follower.cryptovoxels.com` then `su - postgres` then `pg_dump -s cryptovoxels > schema.sql` then scp the dump to your computer
5. `cat schema.sql | psql cryptovoxels`
6. Ok you should have a schema now
7. In this repo - `npm run prod:dump` (you'll need the rds password)
8. `cat cryptovoxels.sql | psql cryptovoxels`
9. Tada! If thor is  kind, you will have a database.

# Testing concurrency

We run multiple dynos in production - we can use `throng` locally to test multiple server instances:

        TEST_WEB_CONCURRENCY=8 npm start

We dont use the `WEB_CONCURRENCY` env variable because we dont want to use throng in production.

# Setup

    npm i -g less-watch-compiler

# Stable mode

The same as `npm start` but does not restart the server on changes (good for when editing views that are server side
rendered and restarts cause too much server load).

    npm run stable

# Using SSL (for webxr etc...)

You need to generate self signed certs (we each get our own so we don't all get pwned by a shared root cert). Do not check this cert in.

    cd openssl
    make

You need to set `voxels.local` to your local machine in your hosts file. You can do the same thing on your windows VR PC to connect to your dev machine by configuring it's DNS or making a record in hosts too. Same with quest devices. 

update your `.env` so things like `ASSET_PATH` points to the correct protocol and address.

Then start the local dev server by running `npm run start:ssl`.

Once you load https://voxels.local:9500/ it will complain about the cert. You need to click on the cert in chrome, 'export it', then add it to your keychain and trust it as a root cert. Make sure no one else gets this cert or you will be pwned so hard.

Be aware that not all services and CORS stuff has been set up as this is written. There might be dragons.

# License

This project is licensed under the [Business Source License 1.1 (BSL 1.1)](LICENSE).

Each commit to this repository transitions to the [MIT License](https://opensource.org/licenses/MIT) three years after the date of the commit.

### Additional Use Grant
You may use the Licensed Work for any purpose that does not compete with Nolan Consulting and provided the Licensed Work only connects to official Nolan Consulting contracts.

### Contributor Agreement
By contributing to this repository, you agree that your contributions (commits) are licensed under this Business Source License 1.1, including the rolling transition to the MIT License three years after the date of your commit.
