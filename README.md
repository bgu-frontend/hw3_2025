## Introduction

## Goals
This task's goals are:
- Adding users to our website. Only logged-in users can create new notes, but guests can view them without adding/editing/deleting notes. For simplicity, the name of the user, their email, the username, and the password, cannot be changed after user creation.
- Minimize user waiting time. 


## Submission
- Coding: 70%, Questions: 30%.
- Your submitted git repo should be *private*, please add 'barashd@post.bgu.ac.il', 'Gurevichronen@gmail.com', 'daninost', and 'Gal-Fadlon' to the list of collaborators.
- Do not use external libraries that provide the pagination component. If in doubt, contact the course staff.
- Deadline: 15.6.25, end of day.
- Additionally, solve the [theoretical questions](https://forms.gle/TBD).
- Use TypeScript, and follow the linter's warnings (see eslint below). The linter can be faulty; use it to get early signs of bugs, the automatic tests will not take away points for linter warnings.
- The ex3 forum is open for questions in Moodle. It's highly recommended to use it for design, technical issues, and any general subject.

- Git repository content:
  - Aim for a minimal repository size that can be cloned and installed: most of the files in github should be code and package dependencies (add package.json, index.html).
  - Don't submit (add to git) .env (it's your secret file which includes passwords- add to gitignore), node_modules dir, package-lock.json, or note json files.
  - the submission commit will be tagged as "submission_hw3".
  - to test your submission, run the presubmission script (in github ). A submission that does not pass the presubmission script, gets a 0 score automatically.
      For example: 
      ```bash
      bash presubmission.sh git@github.com:bgu-frontend/hw3_2025.git <full_.env_path>/.env
      ``` 
      - Tip: You can use a local git directory as the target git repository.
      - Tip: You can make the presubmission script to run automatically during every git push.
      - Tip: sending `-x` flag to bash shows the currently executed line.


## AI
Recommendation about using an AI assistant: You can ask questions and read the answers but never copy them. Understand the details, but write the code yourself. If two people copy the same AI code, it will be considered plagiarism.

## Plagiarism
- We use a plagiarism detector.
-  The person who copies and the person who was copied from are both responsible. 
-  Set your repository private, and don't share your code.

## Prerequisites
### Recommended reading:
-  User administration https://fullstackopen.com/en/part4/, and matching frontend support in part5.
-  Bcrypt format: https://en.wikipedia.org/wiki/Bcrypt.
-  JSON Web Token: https://jwt.io/introduction
-  Routing: https://v5.reactrouter.com/web/guides/quick-start
-  data-testid: https://playwright.dev/docs/locators#locate-by-test-id


## Mongo
-  Add the user details to the notes schema :

```json
{
 title: string;
 author: {
 name: string;
 email: string;
 } | null;
 content: string;
   user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
};

```
-  Add a user collection with the following schema:
```json
{
  name: string,
  email: string,
  username: string,
  passwordHash: string
}
```

## Per User Behaviour 
- Each note's `Edit`/`Delete` buttons, are shown only for the author; the user is logged in, and their email is the same as the name of the note's author.

### Caching
In react, implement the following caching mechanism:
- We'll have 5 (=pagination size) pre-fetched pages.
-  The pages we will store are the pages that are visible in the current page pagination bar (for example, if the current page is 5, and the shown pages are 3,4,5,6,7, then the cached pages are also 3,4,5,6,7).
-  When the user is browsing to a new page:
    - If the current page is in the cache, it will be loaded from it.
    -  Also, asynchronically in the background, the frontend will get the minimal amount of pages needed. For example, when moving from page 5 to 6, only one page should be fetched, since the rest are already in the cache.
        - It's ok to have 5 fetches of 10 notes each, instead of one fetch of 50 notes; it's ok to use the existing 10-notes fetching API.
-  Examples:
    - The first page should be in the cache after build, and not be brought when the user first enters the website.
    -  Moving from page 1 to 2 should not fetch new data to the cache.


## Frontend requirements
- **Routes description**
  - The application will have the following routes: (optional: use react dom router)
    - `/` – Homepage: the same page we saw on the previous exercises, can be seen by all users, even if they did not log in.
  The homepage (when user is not logged in) will show **navigation buttons** that redirect to the login and create user pages:
        - **Login page button**:
            - Text: `Go to Login`
            - `data-testid`: **"go_to_login_button"**
        - **Create User page button**:
            - Text: `Create New User`
            - `data-testid`: **"go_to_create_user_button"**
    
    - `/login` – Login page containing the login form.
    - `/create-user` – Create User page containing the registration form.

    - **Logout button** (`/` homepage when logged in):
        - `data-testid`: **"logout"**
        - Behavior:
            - Deletes the token from React state.
            - The user is now logged out (see: `/` homepage when not logged in)
            - _Comment: It should also be added to a blacklist on the server so it won't be used later. In this exercise, we won't use a blacklist._

    - **Add Note Form** (`/` homepage when logged in): 
        - this button will appear only when logged in. 
        - Naturally, the created note will include the current user's details.
        - Other than that, it's identical to the previous exercise.
    - **Create User form** (`/create-user` route):
    - `data-testid` for form: **"create_user_form"**
    - Fields:
        - `Name`, `data-testid`: **"create_user_form_name"**
        - `Email`, `data-testid`: **"create_user_form_email"**. The email doesn't need to be verified for uniqueness or correctness.
        - `Username`, `data-testid`: **"create_user_form_username"**
        - `Password`, `data-testid`: **"create_user_form_password"**
    - Create User button: (submit)
        - Text: `Create User`
        - `data-testid`: **"create_user_form_create_user"**
    - Behaviour: the user is saved in the database, and redirected back to the homepage (while still logged out).

    - **Login form** (`/login` route):
    - `data-testid` for form: **"login_form"**
    - Fields:
        - `Username`, `data-testid`: **"login_form_username"**
        - `Password`, `data-testid`: **"login_form_password"**
    - Submit button:
        - Text: `Login`
        - `data-testid`: **"login_form_login"**
    - Behaviour: a succesful login redirects the user to the home page, and he/she are now logged in. A failed attempt will print an error of your choice to the user, while staying in the same page.
        
    - Token behavior:
        - After login, the token is saved in React state.
        - All authenticated API requests will send the token via an `'Authorization'` header.
        - _Note: While the flowchart which we've seen in class explains that the token should be saved without exposing it to frontend JavaScript, Full Stack Open actual code stores it in the frontend state — this is for educational purposes, but not secure as HTTP-only cookies._
   


## Backend test requirements- hw3
implement (see https://fullstackopen.com/en/part4/token_authentication):
- Post a request to '/users', to create a new user with the required fields from Mongo.
- Post a request to '/login', to login using a username and a password, return a signed token.

## Implementation - backend error handling - hw3:
Read and use the following error codes:
- 401: Unauthorized: the user is unknown, and needs to authenticate to get a response or incorrect credentials.

## The tester will:
- `git clone <your_submitted_github_repo>`
- `cd <cloned_dir>`
- `git checkout submission_hw3`
- `npm install` from the `frontend` dir (package.json should exist)
- `npm run dev` from the `frontend` dir  (configured to default port 3000)
- Copy a `.env` file into the `backend` dir.
- `npm install` from the `backend` dir (package.json should exist)
- `node index.js` from the `backend` dir (configured to default port 3001)
- Run tests: frontend (playwright) and backend (jest).

## Good luck!

### Suggestions:
- Often, errors are lost between try/catch blocks, frontend/backend communication, and async functions which do not print to the console.
- use a backend errorHandler middleware, as in["Limiting creating new notes to logged-in users
](https://fullstackopen.com/en/part4/token_authentication#limiting-creating-new-notes-to-logged-in-users).
