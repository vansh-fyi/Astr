# Connect Existing Vercel Project to GitHub

## Quick Commands

```bash
# Link your local project to the existing Vercel project
vercel link

# Connect to GitHub (this will prompt you)
vercel git connect
```

When prompted:
- Select your existing Vercel project
- Confirm the GitHub repository: vansh-fyi/Astr
- Choose the main branch

## Environment Variables Setup

After connecting, set your environment variables on Vercel:

```bash
# Set MongoDB URI (you'll be prompted to enter the value)
vercel env add MONGODB_URI

# Or set it directly (paste your MongoDB URI when prompted)
vercel env add MONGODB_URI production
```

Your MongoDB URI from backend/.env:
```
mongodb+srv://vansh-fyi:Midoriya%4011@cluster0.idxp6uk.mongodb.net/?appName=Cluster0
```

## Redeploy with GitHub Connection

After connecting:
1. Any push to `main` will auto-deploy
2. Pull requests will create preview deployments
3. You can still manually deploy with `vercel --prod` if needed

## Verify Connection

Check that GitHub is connected:
```bash
vercel inspect
```

Look for "Git Source" showing your GitHub repo.
