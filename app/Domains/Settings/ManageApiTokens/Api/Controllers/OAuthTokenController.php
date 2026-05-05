<?php

namespace App\Domains\Settings\ManageApiTokens\Api\Controllers;

use App\Http\Controllers\ApiController;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class OAuthTokenController extends ApiController
{
    /**
     * Exchange an OAuth access token for a Monica API token.
     *
     * Validates the Bearer token against the configured OIDC provider's
     * userinfo endpoint, then returns a Sanctum token for the matching user.
     *
     * Requires OIDC_ISSUER to be set in config.
     */
    public function store(Request $request): JsonResponse
    {
        $bearerToken = $request->bearerToken();

        if (! $bearerToken) {
            return $this->respondUnauthorized('No Bearer token provided');
        }

        $issuerURL = config('services.oidc.issuer');

        if (! $issuerURL) {
            return $this->setHTTPStatusCode(503)
                ->setErrorCode(33)
                ->respondWithError('OIDC is not configured on this server. Set OIDC_ISSUER in your environment.');
        }

        $userInfoURL = rtrim($issuerURL, '/').'/userinfo';
        $userInfoResponse = Http::withToken($bearerToken)
            ->acceptJson()
            ->get($userInfoURL);

        if (! $userInfoResponse->ok()) {
            return $this->respondUnauthorized('OAuth token is invalid or expired');
        }

        $email = $userInfoResponse->json('email');

        if (! $email) {
            return $this->respondUnauthorized('OAuth token does not include an email claim');
        }

        $user = User::where('email', $email)->first();

        if (! $user) {
            return $this->respondUnauthorized('No Monica account found for '.$email);
        }

        // Remove previous tokens issued via this flow to avoid accumulation.
        $user->tokens()->where('name', 'mobile-app')->delete();

        $token = $user->createToken('mobile-app', ['abilities:read', 'abilities:write']);

        return response()->json(['token' => $token->plainTextToken]);
    }
}
