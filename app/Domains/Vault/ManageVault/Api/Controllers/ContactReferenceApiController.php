<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Http\Controllers\ApiController;
use Illuminate\Http\Request;

/**
 * @group Vault management
 *
 * @subgroup Reference data
 *
 * Lookup lists the mobile client needs to populate pickers when creating
 * contact modules (e.g. the type required by a piece of contact information).
 */
class ContactReferenceApiController extends ApiController
{
    public function __construct()
    {
        $this->middleware('abilities:read');

        parent::__construct();
    }

    public function index(Request $request, string $vaultId)
    {
        $account = $request->user()->account;
        $vault = $account->vaults()->findOrFail($vaultId);

        return response()->json([
            'data' => [
                'contact_information_types' => $account->contactInformationTypes()
                    ->get()
                    ->map(fn ($type) => [
                        'id' => $type->id,
                        'name' => $type->name,
                        'protocol' => $type->protocol,
                        'type' => $type->type,
                    ]),
                'address_types' => $account->addressTypes()
                    ->get()
                    ->map(fn ($type) => [
                        'id' => $type->id,
                        'name' => $type->name,
                    ]),
                'important_date_types' => $vault->contactImportantDateTypes()
                    ->get()
                    ->map(fn ($type) => [
                        'id' => $type->id,
                        'label' => $type->label,
                    ]),
            ],
        ]);
    }
}
