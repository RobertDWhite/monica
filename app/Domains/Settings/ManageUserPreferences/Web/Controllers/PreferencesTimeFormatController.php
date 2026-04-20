<?php

namespace App\Domains\Settings\ManageUserPreferences\Web\Controllers;

use App\Domains\Settings\ManageUserPreferences\Services\StoreTimeFormatPreference;
use App\Domains\Settings\ManageUserPreferences\Web\ViewHelpers\UserPreferencesIndexViewHelper;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PreferencesTimeFormatController extends Controller
{
    public function store(Request $request)
    {
        $data = [
            'account_id' => Auth::user()->account_id,
            'author_id' => Auth::id(),
            'time_format' => $request->input('timeFormat'),
        ];

        $user = (new StoreTimeFormatPreference)->execute($data);

        return response()->json([
            'data' => UserPreferencesIndexViewHelper::dtoTimeFormat($user),
        ], 200);
    }
}
